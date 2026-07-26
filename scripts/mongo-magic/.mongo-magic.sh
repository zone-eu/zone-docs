#!/usr/bin/env bash

# Install MongoDB on Zone.eu servers automatically.
#
# Usage:
# 1. Copy the script (.mongo-magic.sh) into your HOME directory (e.g., /data01/virt12345/).
# 2. Run the script from the terminal using: "bash .mongo-magic.sh".
#
# Download Instructions:
# You can download this script directly from GitHub using:
# - wget: wget https://raw.githubusercontent.com/raidokulla/mongo-magic/master/.mongo-magic.sh
# - curl: curl -O https://raw.githubusercontent.com/raidokulla/mongo-magic/master/.mongo-magic.sh
#
# Features:
# - Detects the server's OS/architecture and asks MongoDB's official release
#   catalog (downloads.mongodb.org) which binary actually matches it, instead
#   of guessing a filename. When the OS isn't one MongoDB publishes a build
#   for (e.g. Zone.eu's own ZoneOS), it probes a list of known-compatible
#   builds and verifies each one by actually running mongod, rather than
#   trusting a name match. Aborts only if nothing it tries will run.
# - Verifies the SHA-256 checksum of every downloaded artifact.
# - Lets you choose between MongoDB 8.0 (current Long-Term/Major Release,
#   recommended) and 7.0 (previous Major Release, still supported).
# - Always fetches the latest mongosh and MongoDB Database Tools builds.
# - Checks for an existing MongoDB instance and prevents conflicts.
# - Offers to back up the current database before installation.
# - Scales the WiredTiger cache to the chosen PM2 memory limit so MongoDB
#   doesn't get killed in a restart loop on small memory plans.
# - Lets the user select the memory allocation for MongoDB (256M, 512M, 1G, 2G, 3G).
# - Enables the user to specify a custom PM2 app name.
# - Prompts for the creation of a new root user, and an optional additional
#   user with read/write permissions on a database of their choice.
# - Provides instructions for setting up MongoDB as a new PM2 app on Zone.eu servers.
# - Adds mongosh and the database tools to PATH for easy access.
#
# Author: Raido K @ Vellex Digital
# GitHub: https://github.com/raidokulla

set -Eeuo pipefail

# ---------------------------------------------------------------------------
# COLORS & OUTPUT HELPERS
# ---------------------------------------------------------------------------
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

info()    { echo -e "${GREEN}$*${RESET}"; }
warn()    { echo -e "${YELLOW}$*${RESET}"; }
error()   { echo -e "${RED}$*${RESET}" >&2; }
confirm() { local reply; read -r -p "$1 (y/n): " reply; [[ "$reply" =~ ^[Yy]$ ]]; }

trap 'error "Something went wrong on line $LINENO. Aborting."' ERR

SCRATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mongo-magic.XXXXXX")
trap 'rm -rf "$SCRATCH_DIR"' EXIT

# ---------------------------------------------------------------------------
# PREREQUISITE CHECKS
# ---------------------------------------------------------------------------
require_command() {
    command -v "$1" >/dev/null 2>&1 || { error "Required command '$1' was not found. This script is intended for Zone.eu servers."; exit 1; }
}

require_command pm2
require_command node
require_command tar
require_command vs-loopback-ip

if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    error "Neither curl nor wget is available. Cannot download MongoDB."
    exit 1
fi

download() {
    local url="$1" dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fSL --retry 3 --retry-delay 2 -o "$dest" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$dest" "$url"
    else
        error "Neither curl nor wget is available to download files."
        exit 1
    fi
}

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v openssl >/dev/null 2>&1; then
        openssl dgst -sha256 "$1" | awk '{print $NF}'
    fi
}

verify_checksum() {
    local file="$1" expected="$2" actual
    if [ -z "$expected" ]; then
        warn "No checksum provided for $(basename "$file"), skipping verification."
        return 0
    fi
    actual=$(sha256_of "$file")
    if [ -z "$actual" ]; then
        warn "No SHA-256 tool (sha256sum/shasum/openssl) found, skipping verification of $(basename "$file")."
        return 0
    fi
    if [ "$actual" != "$expected" ]; then
        error "Checksum mismatch for $(basename "$file")! Expected $expected, got $actual."
        error "The download may be corrupted or tampered with. Aborting."
        exit 1
    fi
    info "Checksum verified for $(basename "$file")."
}

# ---------------------------------------------------------------------------
# START SCRIPT
# ---------------------------------------------------------------------------
info "Welcome to the MongoDB installation script!"
echo "This script will help you install MongoDB on your Zone.eu server."
echo "Sit back and relax while we take care of everything for you."
sleep 1

LOOPBACK=$(vs-loopback-ip -4)
if [ -z "$LOOPBACK" ]; then
    error "vs-loopback-ip returned no address. Are you running this on a Zone.eu server?"
    exit 1
fi
MONGODB_DIR="$HOME/mongodb"

# Check if MongoDB is already running
if pgrep -x "mongod" > /dev/null; then
    error "MongoDB is already running!"
    echo "Please stop the MongoDB service before running this script."
    exit 1
fi

# Check if a MongoDB directory exists
if [ -d "$MONGODB_DIR/db" ]; then
    warn "Existing MongoDB directory found."
    if confirm "Do you want to back it up before overwriting?"; then
        echo "Backing up existing MongoDB database..."
        tar -czf "$HOME/mongodb_backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$MONGODB_DIR" db
        info "Backup completed successfully."
    fi

    echo "Overwriting existing MongoDB database..."
    find "$MONGODB_DIR/db" -mindepth 1 -delete
fi

# ---------------------------------------------------------------------------
# DETECT OS & ARCHITECTURE
# ---------------------------------------------------------------------------
detect_os_key() {
    if [ ! -r /etc/os-release ]; then
        echo ""
        return
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    local id="${ID:-}" id_like="${ID_LIKE:-}" version="${VERSION_ID:-}"
    local major="${version%%.*}"

    case "$id" in
        zoneos)
            # Zone.eu's own ZoneOS host image: a Gentoo/ChromiumOS-derived,
            # rpm/dpkg-less system (see ZONEOS_BOARD in /etc/os-release) that
            # has no equivalent target in MongoDB's release catalog. Don't
            # guess one here -- leave OS_KEY empty and let the FALLBACK_TARGETS
            # probe below find a build that actually runs, verified by
            # execution rather than by name.
            echo "" ;;
        rhel|centos|rocky|almalinux|ol|fedora)
            echo "rhel${major}" ;;
        ubuntu)
            echo "ubuntu${version//./}" ;;
        debian)
            echo "debian${major}" ;;
        amzn)
            case "$version" in
                2023) echo "amazon2023" ;;
                2)    echo "amazon2" ;;
                *)    echo "amazon" ;;
            esac ;;
        sles|opensuse-leap)
            echo "suse${major}" ;;
        *)
            if [[ "$id_like" == *rhel* || "$id_like" == *fedora* ]]; then
                echo "rhel${major}"
            else
                echo ""
            fi ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)   echo "x86_64" ;;
        aarch64|arm64)  echo "aarch64" ;;
        *)              echo "" ;;
    esac
}

OS_KEY=$(detect_os_key)
ARCH=$(detect_arch)

if [ -z "$ARCH" ]; then
    error "Could not detect this server's CPU architecture (uname -m: $(uname -m))."
    error "Please check https://www.mongodb.com/try/download/community-edition and install manually."
    exit 1
fi

# Targets to try, in order, against MongoDB's release catalog. The detected
# OS_KEY (if any) is always tried first; the rest are a fallback list for
# hosts we can't confidently name -- e.g. Zone.eu's own ZoneOS, which isn't
# a distro MongoDB has ever heard of. Every candidate is downloaded and
# smoke-tested with `mongod --version` before being trusted (see below), so
# a wrong guess here just moves on to the next one instead of silently
# installing a binary that can't run.
FALLBACK_TARGETS=(rhel9 ubuntu2404 debian12 amazon2023 ubuntu2204 rhel8 debian11)

CANDIDATES=()
[ -n "$OS_KEY" ] && CANDIDATES+=("$OS_KEY")
for t in "${FALLBACK_TARGETS[@]}"; do
    [ "$t" != "$OS_KEY" ] && CANDIDATES+=("$t")
done

if [ -n "$OS_KEY" ]; then
    info "Detected platform: ${OS_KEY} / ${ARCH}"
else
    OS_NAME=""
    [ -r /etc/os-release ] && OS_NAME=$(. /etc/os-release; echo "${PRETTY_NAME:-$ID}")
    warn "Could not map this server's OS${OS_NAME:+ ($OS_NAME)} to a MongoDB release-catalog target directly."
    warn "Will probe known-compatible builds (${CANDIDATES[*]}) and use whichever one actually runs here."
fi

# mongosh's feed labels ARM as "arm64" instead of "aarch64"
MONGOSH_ARCH="$ARCH"
[ "$ARCH" = "aarch64" ] && MONGOSH_ARCH="arm64"

# ---------------------------------------------------------------------------
# JSON RESOLVER (matches this server against MongoDB's official release feeds)
# ---------------------------------------------------------------------------
RESOLVE_JS="$SCRATCH_DIR/resolve.js"
cat > "$RESOLVE_JS" <<'JAVASCRIPT'
'use strict';
const fs = require('fs');

const [, , feedPath, arch, matchField, wantedRaw, distroFilter, versionPrefix, edition] = process.argv;

function familyKey(raw) {
  if (!raw) return raw;
  if (/^rhel10/.test(raw)) return 'rhel10';
  if (/^rhel9/.test(raw)) return 'rhel9';
  if (/^rhel8/.test(raw)) return 'rhel8';
  if (/^rhel7/.test(raw)) return 'rhel7';
  return raw;
}

let feed;
try {
  feed = JSON.parse(fs.readFileSync(feedPath, 'utf8'));
} catch (err) {
  console.error(`Could not read/parse feed ${feedPath}: ${err.message}`);
  process.exit(2);
}

const wanted = familyKey(wantedRaw);

let versions = (feed.versions || []).filter((v) => /^\d+\.\d+\.\d+$/.test(v.version));
if (versionPrefix) {
  versions = versions.filter((v) => v.version === versionPrefix || v.version.startsWith(`${versionPrefix}.`));
}

versions.sort((a, b) => {
  const pa = a.version.split('.').map(Number);
  const pb = b.version.split('.').map(Number);
  for (let i = 0; i < 3; i += 1) {
    const diff = (pb[i] || 0) - (pa[i] || 0);
    if (diff !== 0) return diff;
  }
  return 0;
});

for (const v of versions) {
  if (v.release_candidate) continue;
  if (v.production_release === false) continue;
  for (const d of v.downloads || []) {
    if (d.arch !== arch) continue;
    if (distroFilter && d.distro !== distroFilter) continue;
    if (matchField && familyKey(d[matchField]) !== wanted) continue;
    // "targeted" is MongoDB's internal name for the free Community edition;
    // "enterprise" builds require a commercial license. Never fall back
    // silently to Enterprise when Community was requested.
    if (edition && d.edition && d.edition !== edition) continue;
    if (!d.archive || !d.archive.url) continue;
    console.log([v.version, d.archive.url, d.archive.sha256 || ''].join('\t'));
    process.exit(0);
  }
}
process.exit(1);
JAVASCRIPT

resolve_download() {
    # args: feed_file arch match_field wanted_key distro_filter version_prefix edition
    node "$RESOLVE_JS" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

# ---------------------------------------------------------------------------
# SELECT MONGODB VERSION
# ---------------------------------------------------------------------------
info "Select MongoDB version to install:"
echo "  1) 8.0 - Long-Term/Major Release, supported until Oct 2029 (recommended)"
echo "  2) 7.0 - Previous Major Release, supported until Aug 2027"
read -r -p "Enter choice [1]: " version_choice
version_choice=${version_choice:-1}

case "$version_choice" in
    1) MONGO_BRANCH="8.0" ;;
    2) MONGO_BRANCH="7.0" ;;
    *) error "Invalid choice. Exiting."; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# RESOLVE & DOWNLOAD MONGODB SERVER
# ---------------------------------------------------------------------------
info "Looking up a MongoDB ${MONGO_BRANCH} build for this server..."
SERVER_FEED="$SCRATCH_DIR/current.json"
download "https://downloads.mongodb.org/current.json" "$SERVER_FEED"

# CREATE REQUIRED DIRS
mkdir -p "$MONGODB_DIR/log" "$MONGODB_DIR/run" "$MONGODB_DIR/db" "$MONGODB_DIR/mongosh" "$MONGODB_DIR/tools"
cd "$MONGODB_DIR" || { error "Failed to change directory!"; exit 1; }

MONGO_VERSION="" MONGO_TARGET=""
for candidate in "${CANDIDATES[@]}"; do
    if ! RESULT=$(resolve_download "$SERVER_FEED" "$ARCH" target "$candidate" "" "$MONGO_BRANCH" targeted); then
        continue
    fi
    IFS=$'\t' read -r c_version c_url c_sha256 <<< "$RESULT"

    info "Trying MongoDB ${c_version} ('${candidate}' build)..."
    c_archive="$SCRATCH_DIR/$(basename "$c_url")"
    download "$c_url" "$c_archive"
    verify_checksum "$c_archive" "$c_sha256"

    set +o pipefail
    c_dir=$(tar -tzf "$c_archive" | head -n 1 | cut -d/ -f1)
    set -o pipefail
    rm -rf "$SCRATCH_DIR/probe"
    mkdir -p "$SCRATCH_DIR/probe"
    tar -zxf "$c_archive" -C "$SCRATCH_DIR/probe"

    if "$SCRATCH_DIR/probe/$c_dir/bin/mongod" --version > /dev/null 2>&1; then
        rm -rf "$MONGODB_DIR/$c_dir"
        mv "$SCRATCH_DIR/probe/$c_dir" "$MONGODB_DIR/$c_dir"
        ln -sfn "$MONGODB_DIR/$c_dir" "$MONGODB_DIR/mongodb-binary"
        MONGO_VERSION="$c_version"
        MONGO_TARGET="$candidate"
        rm -f "$c_archive"
        info "MongoDB ${MONGO_VERSION} ('${candidate}' build) downloaded, verified, and confirmed runnable."
        break
    fi

    warn "'${candidate}' build downloaded but mongod couldn't run here (likely missing shared libraries); trying next candidate."
    rm -rf "$SCRATCH_DIR/probe" "$c_archive"
done

if [ -z "$MONGO_VERSION" ]; then
    error "None of the candidate MongoDB ${MONGO_BRANCH} builds (${CANDIDATES[*]}) would run on this server."
    error "Please check https://www.mongodb.com/try/download/community-edition and install manually."
    exit 1
fi

# ---------------------------------------------------------------------------
# RESOLVE & DOWNLOAD MONGOSH
# ---------------------------------------------------------------------------
info "Fetching the latest mongosh build..."
MONGOSH_FEED="$SCRATCH_DIR/mongosh.json"
download "https://downloads.mongodb.com/compass/mongosh.json" "$MONGOSH_FEED"

if ! RESULT=$(resolve_download "$MONGOSH_FEED" "$MONGOSH_ARCH" "" "" linux "" ""); then
    error "Could not resolve a mongosh build for ${MONGOSH_ARCH}."
    exit 1
fi
IFS=$'\t' read -r MONGOSH_VERSION MONGOSH_URL MONGOSH_SHA256 <<< "$RESULT"

MONGOSH_ARCHIVE="$SCRATCH_DIR/mongosh.tgz"
download "$MONGOSH_URL" "$MONGOSH_ARCHIVE"
verify_checksum "$MONGOSH_ARCHIVE" "$MONGOSH_SHA256"
tar -zxf "$MONGOSH_ARCHIVE" -C "$MONGODB_DIR/mongosh" --strip-components=1
info "mongosh ${MONGOSH_VERSION} installed."

# ---------------------------------------------------------------------------
# RESOLVE & DOWNLOAD MONGODB DATABASE TOOLS
# ---------------------------------------------------------------------------
info "Fetching the latest MongoDB Database Tools build..."
TOOLS_FEED="$SCRATCH_DIR/tools-release.json"
download "https://downloads.mongodb.org/tools/db/release.json" "$TOOLS_FEED"

TOOLS_VERSION=""
for candidate in "${CANDIDATES[@]}"; do
    if ! RESULT=$(resolve_download "$TOOLS_FEED" "$ARCH" name "$candidate" "" "" ""); then
        continue
    fi
    IFS=$'\t' read -r c_version c_url c_sha256 <<< "$RESULT"
    c_archive="$SCRATCH_DIR/tools.tgz"
    download "$c_url" "$c_archive"
    verify_checksum "$c_archive" "$c_sha256"

    rm -rf "$MONGODB_DIR/tools"
    mkdir -p "$MONGODB_DIR/tools"
    tar -zxf "$c_archive" -C "$MONGODB_DIR/tools" --strip-components=1
    rm -f "$c_archive"

    if "$MONGODB_DIR/tools/bin/mongodump" --version > /dev/null 2>&1; then
        TOOLS_VERSION="$c_version"
        info "MongoDB Database Tools ${TOOLS_VERSION} ('${candidate}' build) installed and confirmed runnable."
        break
    fi

    warn "Database Tools '${candidate}' build couldn't run here; trying next candidate."
    rm -rf "$MONGODB_DIR/tools"
done

if [ -z "$TOOLS_VERSION" ]; then
    warn "Could not find a working MongoDB Database Tools build for this server. Skipping (optional)."
    mkdir -p "$MONGODB_DIR/tools"
fi

# ---------------------------------------------------------------------------
# UPDATE PATH (idempotent)
# ---------------------------------------------------------------------------
PROFILE="$HOME/.bash_profile"
touch "$PROFILE"
if ! grep -qF "$MONGODB_DIR/mongosh/bin" "$PROFILE"; then
    echo "export PATH=\"\$PATH:$MONGODB_DIR/mongosh/bin:$MONGODB_DIR/tools/bin\"" >> "$PROFILE"
    info "Updated PATH in $PROFILE."
fi
# shellcheck disable=SC1090
source "$PROFILE"

# ---------------------------------------------------------------------------
# CREATE MONGO.CFG
# ---------------------------------------------------------------------------
echo "Creating MongoDB configuration file..."
sleep 1

# Ask user for memory limit
info "Select memory limit for MongoDB:"
echo "  1) 256M"
echo "  2) 512M"
echo "  3) 1G"
echo "  4) 2G"
echo "  5) 3G"
read -r -p "Enter choice [3]: " memory_choice
memory_choice=${memory_choice:-3}

# WiredTiger's cache is kept well under the PM2 memory limit so MongoDB
# doesn't get OOM-killed and restart-looped by PM2 on small memory plans.
case "$memory_choice" in
    1) MEMORY="256M"; CACHE_SIZE_GB="0.25" ;;
    2) MEMORY="512M"; CACHE_SIZE_GB="0.25" ;;
    3) MEMORY="1G";   CACHE_SIZE_GB="0.5"  ;;
    4) MEMORY="2G";   CACHE_SIZE_GB="1"    ;;
    5) MEMORY="3G";   CACHE_SIZE_GB="1.5"  ;;
    *) error "Invalid choice. Exiting."; exit 1 ;;
esac

cat > "$MONGODB_DIR/mongo.cfg" << ENDOFFILE
processManagement:
    fork: false
    pidFilePath: "$MONGODB_DIR/run/mongodb-5679.pid"
net:
    bindIp: $LOOPBACK
    port: 5679
    unixDomainSocket:
        enabled: false
systemLog:
    verbosity: 0
    quiet: true
    destination: file
    path: "$MONGODB_DIR/log/mongodb.log"
    logRotate: reopen
    logAppend: true
storage:
    dbPath: "$MONGODB_DIR/db/"
    directoryPerDB: true
    engine: wiredTiger
    wiredTiger:
        engineConfig:
            journalCompressor: snappy
            cacheSizeGB: $CACHE_SIZE_GB
        collectionConfig:
            blockCompressor: snappy
ENDOFFILE

info "Mongo CFG created."
sleep 1

# Ask user for PM2 app name
read -r -p "Enter a name for the PM2 app [mongodb]: " pm2_app_name
pm2_app_name=${pm2_app_name:-mongodb}
pm2_app_name=$(echo "$pm2_app_name" | tr -cd 'A-Za-z0-9_-')
[ -z "$pm2_app_name" ] && pm2_app_name="mongodb"

# CREATE JSON FOR PM2
echo "Creating MongoDB PM2 JSON..."
sleep 1
cat > "$MONGODB_DIR/${pm2_app_name}.pm2.json" << ENDOFFILE
{
  "apps": [{
    "name": "$pm2_app_name",
    "script": "$MONGODB_DIR/mongodb-binary/bin/mongod",
    "args": ["--config", "$MONGODB_DIR/mongo.cfg", "--auth"],
    "interpreter": "none",
    "cwd": "$MONGODB_DIR",
    "max_memory_restart": "$MEMORY"
  }]
}
ENDOFFILE

info "MongoDB PM2 JSON created."
sleep 1

# START MONGODB FIRST TIME
echo "Starting MongoDB..."
sleep 1
pm2 start "$MONGODB_DIR/${pm2_app_name}.pm2.json" || { error "Failed to start MongoDB!"; exit 1; }

# WAIT FOR MONGODB TO START
echo "Checking if MongoDB is running..."
max_attempts=30
attempt=0

while ! pgrep -x mongod > /dev/null; do
    if [ "$attempt" -ge "$max_attempts" ]; then
        error "MongoDB did not start in time. Check the logs with: pm2 logs $pm2_app_name"
        exit 1
    fi
    sleep 1
    attempt=$((attempt + 1))
done

info "MongoDB is up and running."
sleep 1

echo "Checking if mongosh is installed..."
if ! command -v mongosh &> /dev/null; then
    error "Mongosh is not installed or path not added. Please install it manually."
    exit 1
fi

# ---------------------------------------------------------------------------
# CREATE ADMIN DB USER
# ---------------------------------------------------------------------------
info "Creating new root user in ADMIN database."
read -r -p "Enter new ROOT username: " username
until [ -n "$username" ]; do read -r -p "Username cannot be empty. Enter new ROOT username: " username; done
read -rsp "Enter new ROOT password: " password
echo
until [ -n "$password" ]; do read -rsp "Password cannot be empty. Enter new ROOT password: " password; echo; done

# Credentials are passed via environment variables (not string-interpolated
# into the --eval script) so special characters can't break out of the JS
# string or inject arbitrary commands.
MM_USER="$username" MM_PASS="$password" mongosh "$LOOPBACK:5679/admin" --quiet --eval '
db.createUser({
    user: process.env.MM_USER,
    pwd: process.env.MM_PASS,
    roles: [{ role: "root", db: "admin" }]
});
'

# WARNING ABOUT CREATING A NEW USER
warn "WARNING: It is recommended to create a new user with read/write permissions."
if confirm "Do you want to create a new user with limited permissions?"; then
    read -r -p "Enter new USERNAME for LIMITED access: " new_username
    until [ -n "$new_username" ]; do read -r -p "Username cannot be empty. Enter new USERNAME for LIMITED access: " new_username; done
    read -rsp "Enter new PASSWORD for LIMITED access: " new_password
    echo
    until [ -n "$new_password" ]; do read -rsp "Password cannot be empty. Enter new PASSWORD for LIMITED access: " new_password; echo; done
    read -r -p "Enter the name of the DATABASE for the LIMITED user: " db_name
    until [ -n "$db_name" ]; do read -r -p "Database name cannot be empty. Enter the name of the DATABASE for the LIMITED user: " db_name; done

    MM_ROOT_USER="$username" MM_ROOT_PASS="$password" MM_NEW_USER="$new_username" MM_NEW_PASS="$new_password" MM_DB_NAME="$db_name" \
        mongosh "$LOOPBACK:5679/admin" --quiet --eval '
db.auth(process.env.MM_ROOT_USER, process.env.MM_ROOT_PASS);
db.getSiblingDB(process.env.MM_DB_NAME).createUser({
    user: process.env.MM_NEW_USER,
    pwd: process.env.MM_NEW_PASS,
    roles: [{ role: "readWrite", db: process.env.MM_DB_NAME }]
});
'
    info "New user created in $db_name with read/write permissions."
    sleep 1
fi

# ---------------------------------------------------------------------------
# WRAP UP
# ---------------------------------------------------------------------------
info "MongoDB installation completed successfully."
echo "MongoDB version: $MONGO_VERSION (using the '${MONGO_TARGET}' build)"
sleep 1
warn "IMPORTANT: Setup MongoDB as new PM2 app at Zone.eu"
echo "Webhosting -> PM2 and Node.js -> Add new application"
echo "Path for the app: $MONGODB_DIR/${pm2_app_name}.pm2.json"
echo "App name: $pm2_app_name"
echo "Memory limit: $MEMORY"
echo "Start the app and check the logs for any errors."

# CLOSE MONGO USING PM2 (the app will be re-added through the My Zone panel)
echo "Shutting down MongoDB using PM2..."
pm2 stop "$pm2_app_name" || { error "Failed to stop MongoDB!"; exit 1; }
echo "Deleting MongoDB PM2 app..."
pm2 delete "$pm2_app_name" || { error "Failed to delete MongoDB!"; exit 1; }
info "All done. Exiting script."
