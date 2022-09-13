# Install Mongo DB at Zone.eu servers automatically.
# Copy .mongo-magic.sh into your HOME directory (example: /data01/virt12345/)
# Run script from terminal by "bash .mongo-magic.sh"
# Author: Raido K @ Vellex Digital
# https://github.com/raidokulla

#! /usr/bin/bash

# GET LOOPBACK IP
LOOPBACK=$(vs-loopback-ip -4)

# CREATE REQUIRED DIRS
cd ~
mkdir mongodb
cd mongodb
mkdir log run db

# GET MONGODB
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel80-6.0.0.tgz -O download.tgz
tar -zxvf download.tgz

# CREATE SYMLINK FOR EASY UPDATES
ln -s mongodb-linux-x86_64-rhel80-6.0.0 mongodb-binary

# GET MONGOSH
wget https://downloads.mongodb.com/compass/mongosh-1.5.2-linux-x64.tgz -O mongosh.tgz
tar -zxvf mongosh.tgz
echo 'export PATH=$PATH:$HOME/mongodb/mongosh-1.5.2-linux-x64/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile

# GET TOOLS FOR DUMPS AND RECOVERY
wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel80-x86_64-100.5.4.tgz -O tools.tgz
tar -zxvf tools.tgz
echo 'export PATH=$PATH:$HOME/mongodb/mongodb-database-tools-rhel80-x86_64-100.5.4/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile

# CREATE MONGO.CFG
cat > ~/mongodb/mongo.cfg << ENDOFFILE
processManagement:
    fork: false
    pidFilePath: "$PWD/run/mongodb-5679.pid"
net:
    bindIp: $LOOPBACK
    port: 5679
    unixDomainSocket:
        enabled: false
systemLog:
    verbosity: 0
    quiet: true
    destination: file
    path: "$PWD/log/mongodb.log"
    logRotate: reopen
    logAppend: true
storage:
    dbPath: "$PWD/db/"
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

echo "Mongo CFG created"

echo "Creating MongoDB PM2 JSON"

# CREATE JSON FOR PM2
cat > ~/mongodb/mongodb.pm2.json << ENDOFFILE
{
  "apps": [{
    "name": "mongodb",
    "script": "$PWD/mongodb-binary/bin/mongod",
    "args": "--config $PWD/mongo.cfg --auth --wiredTigerEngineConfigString=cache_size=200M",
    "cwd": "$PWD",
    "max_memory_restart" : "128M"
  }]
}
ENDOFFILE

echo "MongoDB PM2 JSON created"

cd ~

echo "Starting MongoDB"
# START MONGODB FIRST TIME
pm2 start mongodb/mongodb.pm2.json
echo "MongoDB started succesfully"

# STOP MONGODB
echo "Stopping MongoDB"
pm2 stop mongodb

cd mongodb

# CREATE ADMIN DB USER
echo "Creating new user"
echo "Enter new username"
read username
echo "Enter new password"
read password

./mongodb-binary/bin/mongod -f ./mongo.cfg --fork

mongosh $USER.loopback.zonevs.eu:5679/admin --eval "db.createUser({
    user:\"$username\",
    pwd:\"$password\",
    roles:[{role:\"userAdminAnyDatabase\",db:\"admin\"},{role:\"readWriteAnyDatabase\",db:\"admin\"}]
})"

# CREATE NEW DATABASE
echo "Creating new database: my-databse"
mongosh $USER.loopback.zonevs.eu:5679/my-database --eval="db"
echo "Databse created, shutting down MongoDB"

# CLOSE MONGO
./mongodb-binary/bin/mongod -f $PWD/mongo.cfg --shutdown

# DO NEXT COMMENTS
echo "Setup MongoDB as new PM2 app at Zone"
echo "Virtuaalserverid -> Veebiserver -> PM2 protsessid (Node.js)"
echo "Path for app: $PWD/mongodb.pm2.json"