# Ghost.js Zone virtuaalserveris

Antud õpetus on testitud Ghost versiooniga **3.38.3**

Allolev töötab kõik eeldusel, et on seadistatud domeeni või alamdomeeni seadetes **mod_proxy** port väärtusega **2368**

Seejärel tuleb üle SSH käivitada järgmised käsud

```bash
# paigaldame vajalikud tööriistad
cd ~
yarn add knex-migrator grunt-cli ember-cli

# paigaldame ghost'i
git clone --recurse-submodules git@github.com:TryGhost/Ghost
cd Ghost

# Vastavalt Ghost'i dokumentatsioonile võib siin arendustsüklid seadistada, 
# seda ei ole vaja esmaseks tööle panekuks / testimiseks
# https://ghost.org/docs/install/source/

# Paigaldamine vajalikud sõlutuvused
yarn setup

# Vastavalt soovile tuleb seaistada konfiguratsioon. Minimaalse konfina tuleb seadistada andmebaas. https://ghost.org/docs/concepts/config/#database NB! zone's on host väärtus tuleb võtta Minu Zone halduspaneelist MySQL alamlehelt
```

Vajalikud seadistused tuleb teha vastalt soovile allolevates failides
+ `config.development.json` 
+ `config.production.json` (see fail tuleb ise luua)

Konfifaili sisu võiks välja näha ümber järgmine:

```json
{
    "url": "https://example.org",
    "database": {
        "client": "mysql",
        "connection": {
            "host": "d{XXXXX}.mysql.zonevs.eu",
            "port": 3306,
            "user": "{your_database_user}",
            "password": "{your_database_password}",
            "database": "{your_database_name}"
        }
    }
}

```

Testimiseks, kas rakendus on õigesti seadistatud, võib käivitada käsu:

```sh
node index.js
```

Edaspidi arendamisel piisab käsust :

```sh
yarn dev
```

Selleks, et rakendus (produktsioonis) ka pärast SSH'st välja logimist käima jääks, tuleb luua **Pm2** konf. Faili loome asikohta `~/Ghost/pm2.config.json` sisuga:

```json

{
  "apps": [{
    "name": "ghost",
    "script": "./index.js",
    "cwd":"./Ghost",
    "max_memory_restart" : "128M",
    "env": {
      "NODE_ENV": "production",
      "GHOST_NODE_VERSION_CHECK": "false"
    }
  }]
}
```

Ning seadistame rakenduse Minu Zone virtuaalserveri seadistuste all

`Virtuaalserverid` -> `Veebiserver` -> `PM2 protsessid (Node.js)`

Seal tuleb vajutada nuppu `Lisa uus Node.js rakendus`

Täita tuleb väljad

| väli | väärtus |
| --- | --- |
| Rakenduse nimi | Ghost |
| Skript või Pm2 .JSON | Ghost/pm2.config.json |
| Maksimaalne mälukasutus | võib jätta seadistamata, kuna on juba seadistatud pm2 confi failis. |

Ning vajuta nuppu `Salvesta muudatused`

Rakendus võiks hakata tööle paari minu jooksul. Kui rakendus tööle ei hakka, siis saab haldusliidesest kopeerida käsurea, millega rakendus käivitati ning parandada vead vastavalt väljundile.

