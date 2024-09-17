# Mongo Magic

## Overview
Mongo Magic is a bash script designed to automate the installation and setup of MongoDB on Zone.eu servers. The script provides various options for configuration, ensuring a smooth installation process tailored to your needs.

## Features
- Checks for existing MongoDB instances to prevent conflicts.
- Offers to back up the current database before installation.
- Allows selection between MongoDB versions 6.0 and 7.0.
- Lets you choose the memory allocation for MongoDB from predefined options (256M, 512M, 1G, 2G, 3G).
- Enables specification of a custom PM2 app name.
- Automatically checks for and installs compatible MongoDB tools.
- Prompts for the creation of a new user with root access and an optional additional user with read/write permissions.
- Prompts the user to name the new database with limited access.
- Provides instructions for setting up MongoDB as a new PM2 app on Zone.eu servers.
- Adds the mongosh binary to the PATH for easy access.

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