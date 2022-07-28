# MongoDB zone virtuaalserveris

Autor: [Ingmar Aasoja](https://github.com/ybr-nx) 

Antud õpetus on semi-official. Ehk annab suuna kätte, aga ametlike klienditoe kanalite kaudu tuge ei pakuta.

Õpetus eeldab, et on seadistatud SSH ligipääs. [SSH ühenduse loomine](https://help.zone.eu/kb/ssh-uhenduse-loomine/)


## 1. Laadime alla MonoDB binaari ning seadistame _symlink_'i

```sh
mkdir mongodb
cd mongodb
wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel80-6.0.0.tgz -O download.tgz
tar -zxvf download.tgz

# symlink annab võimaluse muuta lihtsamalt mongodb versiooni ilma konfe muutmata
ln -s mongodb-linux-x86_64-rhel80-6.0.0 mongodb-binary
```

Mongodb'ga ühendamiseks käsurealt, paigaldame ka `mongosh` tööriista

```
wget https://downloads.mongodb.com/compass/mongosh-1.5.2-linux-x64.tgz -O mongosh.tgz
tar -zxvf mongosh.tgz
echo 'export PATH=$PATH:$HOME/mongodb/mongosh-1.5.2-linux-x64/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
```

Samuti on vaja mongodb halduse käsurea tööriistu, millega teha andmetest _dump'e_ ning neid taastada.

```sh

wget https://fastdl.mongodb.org/tools/db/mongodb-database-tools-rhel80-x86_64-100.5.4.tgz -O tools.tgz
tar -zxvf tools.tgz
echo 'export PATH=$PATH:$HOME/mongodb/mongodb-database-tools-rhel80-x86_64-100.5.4/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
```

## 2. Loome vajaliku keskkonna ning seadistused

Allpool loodavates failides tuleb teha vajalikud asendused:
+ `/dataXX/virtXXXX` tuleb asendada enda ssh kasutaja kodukaustaga kaustaga.
+ `127.XX.XX.XX` tuleb asendada enda loopback IP'ga, mille näeb käivitades käsku `vs-loopback-ip -4`
+ `virtXXXX` tuleb asendada enda ssh kasutajanimega.

MongoDB eeldab, et vajalikud kaustad on juba loodud

```
mkdir log run db
```


Loome MongoDB konfiguratsioonifaili

```sh
nano $HOME/mongodb/mongo.cfg
```

```yml
processManagement:
    fork: false
    pidFilePath: /dataXX/virtXXXX/mongodb/run/mongodb-5679.pid
net:
    bindIp: 127.XX.XX.XX
    port: 5679
    unixDomainSocket:
        enabled: false
systemLog:
    verbosity: 0
    quiet: true
    destination: file
    path: /dataXX/virtXXXX/mongodb/log/mongodb.log
    logRotate: reopen
    logAppend: true
storage:
    dbPath: /dataXX/virtXXXX/mongodb/db/
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

```

Loome PM2 konfiguratsioonifaili

```sh
nano $HOME/mongodb/mongodb.pm2.json
```

```json
{
  "apps": [{
    "name": "mongodb",
    "script": "./mongodb-binary/bin/mongod",
    "args": "--config /dataXX/virtXXXX/mongodb/mongo.cfg --auth --wiredTigerEngineConfigString=cache_size=200M",
    "cwd":"./mongodb",
    "max_memory_restart" : "128M",
  }]
}
```

## 3. MongoDB esmane käivitamine

Kindlaks tegemaks, et seadistused said tehtud õigesti, käivitame esialgu MongoDB manuaalselt käskudega.

```
cd ~
pm2 start mongodb/mongodb.pm2.json
```

Pm2 väjundis peaks olema aru saada, et MongoDB töötab. Kontrollida saab seda käsuga `pm2 show mongodb` Kuna meil on see hetkel käivitatud nii, et autentimine on aktiveeritud, siis peame me korraks selle kinni panema ning seadistama kasutajad. 

Peatame rakenduse

```
pm2 stop mongodb
```

## 4. Loome andmebaasi kasutaja

**NB!** mongodb ei tohi sel hetkel töötada

Kõigepeal tuleb välja mõelda endale kasutajanime/salasõna paar. Näidises kasutame:

**u: kasutaja**
**p: salasona**

Antud õpetuses seadistame ainult ühe kasutaja. Soovitatav on kasutajate ja andmebaaside halduseks luua eraldi kasutajad. Selle kohta saab täpsemalt lugeda MongoDB dokumentatsioonist:
https://docs.mongodb.com/manual/reference/method/db.createUser/


Liigume oma MongoDB kodukataloogi

```
cd mongodb
```


Käivitame MongoDB autentimisseadeteta

```
./mongodb-binary/bin/mongod -f /dataXX/virtXXXX/mongodb/mongo.cfg --fork
```

Edukas väljund peaks olema

```
about to fork child process, waiting until server is ready for connections.
forked process: 2790
child process started successfully, parent exiting
```

Loome kasutaja koos vajalike õigustega

```
mongosh virtXXXX.loopback.zonevs.eu:5679/admin --eval "db.createUser({
    user:\"kasutaja\",
    pwd:\"salasona\",
    roles:[{role:\"userAdminAnyDatabase\",db:\"admin\"},{role:\"readWriteAnyDatabase\",db:\"admin\"}]
})"
```

Väljundi lõpp võiks olla umbes selline

```json
{ ok: 1 }

```

Nüüd, kus on meil kasutaja loodud, loome ka andmebaasi andmete jaoks. Paneme sellele nimeks `my-database`. Seda saab teha lihtsa käsuga

```
mongosh virtXXXX.loopback.zonevs.eu:5679/my-database --eval="db"
```

Väljundi viimane rida peaks kuvama loodud andmebaasi nime

```
my-database
```

Nüüd, kus on meil seadistatud asutaja, peame me mongo ka nii käivitama, et autentimist nõutaks. Selleks paneme käimas oleva mongo kinni ning käivitame selle uuesti läbi pm2 (kirjeldatud punktis nr. 5)

```
./mongodb-binary/bin/mongod -f /dataXX/virtXXXX/mongodb/mongo.cfg --shutdown
```

## 5. Seadistame rakenduse virtuaalserveri halduses

`Virtuaalserverid` -> `Veebiserver` -> `PM2 protsessid (Node.js)`

Seal tuleb vajutada nuppu `Lisa uus Node.js rakendus`

Täita tuleb väljad

| väli | väärtus |
| --- | --- |
| Rakenduse nimi | MongoDB |
| Skript või Pm2 .JSON | mongodb/mongodb.pm2.json |
| Maksimaalne mälukasutus | võib jätta seadistamata, kuna on juba seadistatud pm2 failis serveris. |

Ning vajuta nuppu `Salvesta muudatused`

Paari minuti pärast peaks pm2 näitama, et rakendus on aktiivne. Seda saab kontrollida käsuga

```
pm2 show mongodb
```

## 6. Testimine

Testimaks, kas kõik töötab, võib kasutada alljärgnevaid käske

```sh

# Käivitame MongoDB kliendi
mongosh  virtXXXX.loopback.zonevs.eu:5679 -u kasutaja -p salasona --authenticationDatabase admin

# Järgnevad käsud võiksid kõik toimida
use my-database
db.asjad.insert({sissekanne:'Esimene sissekanne'});
db.asjad.find();
db.asjad.drop();
```

## 7. Andmebaasi _dump_ & _restore_

Kuna varukoopiaid tehakse virtuaalserveris failisüsteemi tasandil ning selle tegemise hetkel võib failisüsteemis olla andmebaasi seis poolik, siis on soovitatav teha ise nö. dump varukoopiaid.

### 7.1 Andmete dumpimine failisüsteemi

```
mongodump --host virtXXXX.loopback.zonevs.eu --port 5679 --db my-database --username kasutaja --password salasona --authenticationDatabase admin --out $HOME/mongodb/dump
```

### 7.2 Taastame andmebaasi

```
mongorestore --host virtXXXX.loopback.zonevs.eu --port 5679 --db my-database --username kasutaja --password salasona --authenticationDatabase admin $HOME/mongodb/dump/[andmebaasi nimi, näiteks `my-database`]
```
