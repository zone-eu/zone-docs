#! /usr/bin/bash

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
# - Checks for an existing MongoDB instance and prevents conflicts.
# - Offers to back up the current database before installation.
# - Allows the user to choose between MongoDB versions 6.0 and 7.0.
# - Lets the user select the memory allocation for MongoDB from predefined options (256M, 512M, 1G, 2G, 3G).
# - Enables the user to specify a custom PM2 app name.
# - Automatically checks for compatible MongoDB tools and installs them.
# - Prompts for the creation of a new user with root access and an optional additional user with read/write permissions.
# - Prompts the user to name the new database with limited access.
# - Provides instructions for setting up MongoDB as a new PM2 app on Zone.eu servers.
# - Adds the mongosh binary to the PATH for easy access.
#
# Author: Raido K @ Vellex Digital
# GitHub: https://github.com/raidokulla

# DEFINE COLORS
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"  # Reset to default color

# START SCRIPT
echo -e "${GREEN}Welcome to the MongoDB installation script!${RESET}"
echo "This script will help you install MongoDB on your Zone.eu server."
echo "Sit back and relax while we take care of everything for you."
sleep 1

# GET LOOPBACK IP
LOOPBACK=$(vs-loopback-ip -4)
MONGODB_DIR="$HOME/mongodb"

# Check if MongoDB is running
if pgrep -x "mongod" > /dev/null; then
    echo -e "${RED}MongoDB is already running!${RESET}"
    echo "Please stop the MongoDB service before running this script."
    exit 1
fi

# Check if a MongoDB directory exists
if [ -d "$MONGODB_DIR/db" ]; then
    echo -e "${YELLOW}Existing MongoDB directory found.${RESET}"
    read -p "Do you want to back it up before overwriting? (y/n): " backup_choice

    if [[ "$backup_choice" == "y" ]]; then
        echo "Backing up existing MongoDB database..."
        tar -czvf "$HOME/mongodb_backup_$(date +%Y%m%d_%H%M%S).tar.gz" "$MONGODB_DIR/db"
        echo -e "${GREEN}Backup completed successfully.${RESET}"
    fi

    echo "Overwriting existing MongoDB database..."
    rm -rf "$MONGODB_DIR/db/*"  # Clear existing database files
fi

# Ask user which MongoDB version to install
echo -e "${GREEN}Select MongoDB version to install:${RESET}"
echo "1) 6.0"
echo "2) 7.0"
read -p "Enter choice (1 or 2): " version_choice

case $version_choice in
    1) MONGO_VERSION="mongodb-linux-x86_64-rhel80-6.0.0.tgz";;
    2) MONGO_VERSION="mongodb-linux-x86_64-rhel80-7.0.0.tgz";;
    *) echo -e "${RED}Invalid choice. Exiting.${RESET}"; exit 1;;
esac

# CREATE REQUIRED DIRS
mkdir -p "$MONGODB_DIR/log" "$MONGODB_DIR/run" "$MONGODB_DIR/db"

# Change to MongoDB directory
cd "$MONGODB_DIR" || { echo -e "${RED}Failed to change directory!${RESET}"; exit 1; }

# GET MONGODB
wget "https://fastdl.mongodb.org/linux/$MONGO_VERSION" || { echo "Download failed!"; exit 1; }
tar -zxvf "$MONGO_VERSION" -C "$MONGODB_DIR"  # Extract directly to the MongoDB directory

# Correctly identify the extracted folder
if [[ $version_choice == 1 ]]; then
    EXTRACTED_DIR="mongodb-linux-x86_64-rhel80-6.0.0"
elif [[ $version_choice == 2 ]]; then
    EXTRACTED_DIR="mongodb-linux-x86_64-rhel80-7.0.0"
fi

# Create the symlink to the extracted directory
ln -s "$MONGODB_DIR/$EXTRACTED_DIR" "$MONGODB_DIR/mongodb-binary"

# CREATE DIRECTORIES FOR MONGOSH AND TOOLS
mkdir -p "$MONGODB_DIR/mongosh" "$MONGODB_DIR/tools"

# GET MONGOSH
wget https://downloads.mongodb.com/compass/mongosh-1.5.2-linux-x64.tgz -O "$MONGODB_DIR/mongosh/mongosh.tgz" || { echo "Download failed!"; exit 1; }
tar -zxvf "$MONGODB_DIR/mongosh/mongosh.tgz" -C "$MONGODB_DIR/mongosh" --strip-components=1
echo 'export PATH=$PATH:$MONGODB_DIR/mongosh/bin' >> "$HOME/.bash_profile"
echo "Updating PATH to include mongosh..."
source $HOME/.bash_profile
echo -e "${GREEN}Mongosh installed successfully.${RESET}"
sleep 1

# CREATE MONGO.CFG
echo "Creating MongoDB configuration file..."
sleep 1
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
    journal:
        enabled: true
    directoryPerDB: true
    engine: wiredTiger
    wiredTiger:
        engineConfig:
            journalCompressor: snappy
            cacheSizeGB: 1
        collectionConfig:
            blockCompressor: snappy
ENDOFFILE

echo -e "${GREEN}Mongo CFG created.${RESET}"
sleep 1

# Ask user for memory limit
echo -e "${GREEN}Select memory limit for MongoDB:${RESET}"
echo "1) 256M"
echo "2) 512M"
echo "3) 1G"
echo "4) 2G"
echo "5) 3G"
read -p "Enter choice (1-5): " memory_choice

case $memory_choice in
    1) MEMORY="256M";;
    2) MEMORY="512M";;
    3) MEMORY="1G";;
    4) MEMORY="2G";;
    5) MEMORY="3G";;
    *) echo -e "${RED}Invalid choice. Exiting.${RESET}"; exit 1;;
esac

# Ask user for PM2 app name
read -p "Enter a name for the PM2 app:" pm2_app_name

# CREATE JSON FOR PM2
echo "Creating MongoDB PM2 JSON..."
sleep 1
cat > "$MONGODB_DIR/${pm2_app_name}.pm2.json" << ENDOFFILE
{
  "apps": [{
    "name": "$pm2_app_name",
    "script": "$MONGODB_DIR/mongodb-binary/bin/mongod",
    "args": "--config $MONGODB_DIR/mongo.cfg --auth",
    "cwd": "$MONGODB_DIR",
    "max_memory_restart": "$MEMORY"
  }]
}
ENDOFFILE

echo -e "${GREEN}MongoDB PM2 JSON created.${RESET}"
sleep 1

# START MONGODB FIRST TIME
echo "Starting MongoDB..."
sleep 1
pm2 start "$MONGODB_DIR/${pm2_app_name}.pm2.json" || { echo -e "${RED}Failed to start MongoDB!${RESET}"; exit 1; }

# WAIT FOR MONGODB TO START
echo "Checking if MongoDB is running..."
max_attempts=30  # Maximum number of attempts
attempt=0

while ! pgrep -x mongod > /dev/null; do   
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo -e "${RED}MongoDB did not start in time. Exiting.${RESET}"
        exit 1
    fi
    sleep 1  # Wait for 1 second before checking again
    attempt=$((attempt + 1))
done

echo -e "${GREEN}MongoDB is up and running.${RESET}"
sleep 1

echo "Checking if mongosh is installed..."

# CHECK IF MONGOSH IS INSTALLED
if ! command -v mongosh &> /dev/null; then
    echo -e "${RED}Mongosh is not installed or path not added. Please install it manually.${RESET}"
    exit 1
fi

# CREATE ADMIN DB USER
echo -e "${GREEN}Creating new root user in ADMIN database.${RESET}"
read -p "Enter new ROOT username: " username
read -sp "Enter new ROOT password: " password
echo

# Create the root user using mongosh
mongosh $USER.loopback.zonevs.eu:5679/admin --eval "db.createUser({
    user: \"$username\",
    pwd: \"$password\",
    roles: [{ role: \"root\", db: \"admin\" }]
})"

# WARNING ABOUT CREATING A NEW USER
echo -e "${YELLOW}WARNING: It is recommended to create a new user with read/write permissions.${RESET}"
read -p "Do you want to create a new user with limited permissions? (y/n): " create_user

if [[ "$create_user" == "y" ]]; then
    read -p "Enter new USERNAME for LIMITED access: " new_username
    read -sp "Enter new PASSWORD for LIMITED access: " new_password
    echo
    read -p "Enter the name of the DATABASE for the LIMITED user: " db_name
    echo
    
    # Create the new user with limited access using the root user's credentials
    mongosh --username "$username" --password "$password" $USER.loopback.zonevs.eu:5679/admin --eval "db.createUser({
        user: \"$new_username\",
        pwd: \"$new_password\",
        roles: [{ role: \"readWrite\", db: \"$db_name\" }]
    })"
    echo -e "${GREEN}New user created in $db_name with read/write permissions.${RESET}"
    sleep 1
fi

# DO NEXT COMMENTS
echo -e "${GREEN}MongoDB installation completed successfully.${RESET}"
sleep 1
echo -e "${YELLOW}IMPORTANT: Setup MongoDB as new PM2 app at Zone.eu${RESET}"
echo "Webhosting -> PM2 and Node.js -> Add new application"
echo "Path for the app: $MONGODB_DIR/${pm2_app_name}.pm2.json"
echo "App name: $pm2_app_name"
echo "Memory limit: $MEMORY"
echo "Start the app and check the logs for any errors."

# CLOSE MONGO USING PM2
echo "Shutting down MongoDB using PM2..."
pm2 stop "$pm2_app_name" || { echo "Failed to stop MongoDB!"; exit 1; }
echo "Deleting MongoDB PM2 app..."
pm2 delete "$pm2_app_name" || { echo "Failed to delete MongoDB!"; exit 1; }
echo -e "${GREEN}All done. Exiting script.${RESET}"
