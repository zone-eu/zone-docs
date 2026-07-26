# Mongo Magic

## Overview
Mongo Magic is a bash script designed to automate the installation and setup of MongoDB on Zone.eu servers. The script provides various options for configuration, ensuring a smooth installation process tailored to your needs.

## Features
- Detects the server's OS and architecture and cross-checks it against MongoDB's
  official release catalog (`downloads.mongodb.org`) to pick the exact right
  binary, rather than guessing a filename. When the OS isn't one MongoDB
  publishes a build for (e.g. Zone.eu's own ZoneOS, which has no rpm/dpkg
  and no equivalent in MongoDB's catalog), it probes a short list of
  known-compatible builds and verifies each one by actually running `mongod`,
  rather than trusting a name match. It only aborts if nothing it tries runs.
- Verifies the SHA-256 checksum of every downloaded artifact.
- Only ever installs the free Community edition (never the commercial Enterprise
  build, even though both are listed side by side in MongoDB's feeds).
- Lets you choose between MongoDB 8.0 (current Long-Term/Major Release,
  recommended) and 7.0 (previous Major Release, still supported).
- Always installs the latest mongosh and MongoDB Database Tools builds.
- Checks for existing MongoDB instances to prevent conflicts.
- Offers to back up the current database before installation.
- Scales the WiredTiger cache size to the chosen PM2 memory limit so MongoDB
  doesn't get killed in a restart loop on small memory plans.
- Lets you choose the memory allocation for MongoDB from predefined options (256M, 512M, 1G, 2G, 3G).
- Enables specification of a custom PM2 app name.
- Prompts for the creation of a new user with root access and an optional additional user with read/write permissions.
- Prompts the user to name the new database with limited access.
- Provides instructions for setting up MongoDB as a new PM2 app on Zone.eu servers.
- Adds mongosh and the MongoDB Database Tools to PATH for easy access.

## Supported platforms
The script auto-detects RHEL-family (RHEL, CentOS, Rocky, AlmaLinux), Debian,
Ubuntu, Amazon Linux, and SUSE hosts on x86_64/aarch64. On hosts it can't
confidently name -- notably Zone.eu's own ZoneOS, a Gentoo/ChromiumOS-derived
image with no package manager at all -- it instead tries a short list of
known-compatible builds (RHEL 9/8, Ubuntu 24.04/22.04, Debian 12/11, Amazon
Linux 2023) and keeps whichever one actually runs `mongod` successfully. If
none of them run, or MongoDB doesn't publish a matching build for the
architecture, the script stops and points you to the
[MongoDB Download Center](https://www.mongodb.com/try/download/community-edition)
instead of guessing.

## Installation

### Download the Script
You can download the script directly from GitHub using:

- Using `wget`:
  ```bash
  wget https://raw.githubusercontent.com/raidokulla/mongo-magic/master/.mongo-magic.sh
  ```

- Using `curl`:
  ```bash
  curl -O https://raw.githubusercontent.com/raidokulla/mongo-magic/master/.mongo-magic.sh
  ```

### Run the Script
1. Copy the script to your HOME directory (e.g., `/data01/virt12345/`).
2. Run the script from the terminal:
   ```bash
   bash .mongo-magic.sh
   ```

## Author
Raido K @ Vellex Digital  
[GitHub Repository](https://github.com/raidokulla/mongo-magic)

## License
This project is open-source and available under the [MIT License](LICENSE).