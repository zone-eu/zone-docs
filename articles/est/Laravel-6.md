# Laravel 6.0 paigaldamine ning seadistamine Zone virtuaalserveris

Autor: [Ingmar Aasoja](https://github.com/ybr-nx)

Laraveli paigaldamine jagatud majutuses pole raketiteadus. Käesolevas juhendis näitan milliste Zone poolt pakutavate abivahenditega on võimalik Laravelist paremini aru saada ja seda oma eesmärkide saavutamiseks ära kasutada. Postituse lõpuosas kirjeldan ka mõningaid keerukamaid nüansse, mis võivad jagatud keskondades arendades kõvemaks pähkliks olla ka kogunenumal programmeerijal.

Eeldan, et lugeja on tutvunud Laraveli põhitõdedega, kuid soovitan juhendist paremaks arusaamiseks vajadusel kiigata dokumentatsiooni poole: [Installation - Laravel - The PHP Framework For Web Artisans](https://laravel.com/docs/6.0)

## Nõuded teenuspaketile
Laravelil ei ole erilisi nõudmiseid teenuspaketile, Zones töötab see väga sujuvalt ka Virtuaalserveri veebimajutusteenuse soodsaima paketiga. Enamate võimalustega paketti läheb reeglina vaja ainult edasjõudnutele mõeldud võimaluste kasutamiseks, nagu näiteks:

* Redis (Cache, sessioonid, Queue)
* MongoDB (Moloquent, Queue)
* Websockets (Laravel Echo, Hot Module Replacement)

## Infot juhendi kohta
Minu näidis-skriptides on kasutatud reaalselt loodud virtuaalserverit ning selle katalooge. Selleks, et antud õpetust oma Virtuaalserveris järgida, võib oma analoogsed kataloogid (asukohad failipuus) tuletada järgmiselt:

* Õpetuses kasutatava kasutajakonto kodukataloog: `/data01/virt75146`
Selle kataloogi oma analoogi leiad käivitades oma virtuaalserveris käsureal käsu `echo $HOME`

* Õpetuses kasutatava virtuaalserveri juurkataloog: `/data01/virt75146/domeenid/www.laravel.miljonivaade.eu`
See kataloog on tuletatud `echo $HOME` väljundile lisatud virtuaalserveri kataloogist `/domeenid/www.{virtuaalserveri.domeen}`

Kõik juhendis edaspidi viidatud käsud, millele ei eelne juhist vahetada kataloogi  `cd /mingi/asukoht` käsuga, tuleb käivitada rakenduse juurkataloogis, milleks käesoleva juhendi kontekstis on `/data01/virt75146/domeenid/www.laravel.miljonivaade.eu/rakendus`

## 1. Zone virtuaalserveri seadistamine

### 1.1 SSH

Kordamine on tarkuse ema, kuid blogipost kisub pikaks ilma SSH kasutusjuhendit ümber kirjutamatagi, mistõttu siinkohal suunan teid abikeskonda: https://help.zone.eu/kb/ssh-uhenduse-loomine/

### 1.2 MariaDB & MySQL

Jällegi viilin täpsemate juhiste kirjutamisest ja viitan siikohal uuesti blogipostile, kus seda teemat on juba käsitletud, täpsemalt punktile **1.2**: https://blog.zone.ee/2018/06/05/gitea-alternatiiv-githubile-mis-tootab-zone-virtuaalserveris/

### 1.3 Redis

Redise kasutusele võtmine on meie juures tänu Minu Zone keskkonnale äärmiselt lihtne.

Ava leht `Virtuaalserveri Haldus` -> `Andmebaasid` -> `Redis` ja vajuta lehel ON/OFF nuppu (ainuke nupp lehel). 

Minuti jooksul Redis käivitatakse ning vajalikud ligipääsuandmed ilmuvad samale lehele.

### 1.4 HTTP(S) ligipääs

Soovitan muuta veebiserveri poolt kasutatavat juurkataloogi nii, et see ühtiks Laraveli rakenduse ülesehitusega. 

Olenevalt sellest, kas rakendus paigaldatakse peadomeenile või alamdomeenile, tuleb minna vastavalt Apache seadistustesse:

`Virtuaalserveri Haldus` ->
​    -> `Seaded` -> `HTTPS` -> `Muuda`
​    -> `Alamdomeenid` -> `HTTPS` -> `Muuda`

**Apache veebiserver -> Kataloog** – vali kataloog, kuhu plaanid rakenduse paigaldada ning lisa lõppu **public**. Näiteks **rakendus/public**

**PHP -> Režiim** – vali vähemalt **7.3 FastCGI**.

Juhul, kui on plaan kasutada ka *websocket*'eid, pead **HTTPS IP-address** väljale sisestama su serverile eraldatud IP-aadressi (mille saad küsida meie klienditeenindusest). Hiljem *websocket*'eid seadistades tuleb sellele IP-aadressile teha portide suunamine.

Salvesta muudatused.

### 1.4.1 PHP ja laiendused

Pärast veebiserveri muudatuste salvestamist vaata veel üle PHP laiendused. 

Vajuta nuppu **PHP laiendused** ja deaktiveeri **Redis**. Redise laienduse klassi nimi läheb konflikti Laraveli sisese Fascade'iga ning Redisega suhtlemiseks kasutab Laravel **predis** nimelist pakki, mis seda laiendust ei kasuta. 

Kui on soov kasutada PhpRedis moodulit, siis peab muutma Laravelis aliase **Redis** endale sobivaks, kuid siin me sellel detailsemalt ei peatu. 

Kui on soov kasutada MongoDB'd, aktiveeri **MongoDB** laiendus.

### 1.5 MongoDB

MongoDB kasutamise õpetus on käesoleva blogipostituses kontekstis rohkem äärmemärkus ning selle alampunkti läbimiseks pole otsest vajadust.

`Virtuaalserveri Haldus` -> `Andmebaasid` -> `MongoDB`

Sarnaselt Redise seadistamisele on vaja vajutada vaid ON/OFF nuppu ning kogu ligipääsuks vajalik info kuvatakse samal lehel.

## 2. Laraveli rakenduse paigaldus

## 2.1 Laravel raamistiku paigaldus
Logi SSH'ga virtuaalserverisse sisse ja liigu kausta, kus peaks tulevikus asuma kaust **rakendus** ning milles olevast **public** kaustast seadistasime Apache serveri rakendust serveerima.

Meie näite puhul:
```
cd ~/domeenid/www.laravel.miljonivaade.eu
```

Käivita käsk, mis paigaldab Laravel raamistiku:
```
composer create-project --prefer-dist laravel/laravel="6.0" rakendus
```

Selle käsuga tekitatakse kaust `rakendus`, mis on edaspidi rakenduse juurkataloogiks ning milles enamus siinses juhendis kirjeldatud käske käivitada tuleb.

Sellega on Laravel paigaldatud ning külastades brauseriga aadressi https://laravel.miljonivaade.eu kuvatakse sulle Laraveli standardne esileht. Edasi on tuleb sul oma äranägemise järgi seadistada Laraveli konfiguratsioon.

## 2.2 Kasutajaliides ja autentimise initsialiseerimine
Kui soovid kasutada Laraveli poolt eelpaigaldatud UI arendusmeetodeid, seadista vajalikud **Node.js** pakid ning näiteks **Vue.js** eelseadistatud skriptid. Alates versioonist 6.0 on UI lahku löödud eraldi pakiks. 

Seadista **Vue.js UI**:
```sh
// paigalda laravel/ui
composer require laravel/ui --dev

// seadista vue
php artisan ui vue

// genereeri sisselogimine ja registreerimine
php artisan ui vue --auth

// Paigalda UI arenduseks vajalikud **Node.js** moodulid:
npm install
```

Veendumaks, et kõik toimis, käivita käsk:
```sh
npm run dev
```

Kui kõik toimis, peaks väljund olema järgmine:

```
 DONE  Compiled successfully in 7207ms      11:14:20 AM

       Asset      Size   Chunks             Chunk Names
/css/app.css   173 KiB  /js/app  [emitted]  /js/app
  /js/app.js  1.38 MiB  /js/app  [emitted]  /js/app

```

Asendame näidiseks faili `resources/views/welcome.blade.php` sisuga:
```php
@extends('layouts.app')

@section('content')
    <example-component></example-component>
@endsection
```

Minnes nüüd aadressile `https://laravel.miljonivaade.eu/`, peaks kuvatama teksti **I'm an example component.**

Eelnevast võib täpsemalt lugeda ka dokumentatsioonist:
[JavaScript & CSS Scaffolding - Laravel - The PHP Framework For Web Artisans](https://laravel.com/docs/6.0/frontend)


## 3. MariaDB (MySQL)

### 3.1 Ligipääsu seadistamine

Laravel kasutab keskkonnamuutujate halduseks dotenv pakki. Seadistame `.env` failis andmebaasi ligipääsu ja määrame väärtused järgmistele ridadele:

```
DB_HOST={mysql aadress}
DB_DATABASE={andmebaasi nimi}
DB_USERNAME={andmebaasi kasutajanimi}
DB_PASSWORD={andmebaasi parool}
```

Vajaliku info (nt MariaDB serveri aadressi) leiad Virtuaaserveri haldusest MySQL/MariaDB alampunktist.

MariaDB ühenduse toimivust saab katsetada käivitades paigaldusskripti automaatselt paigaldatud migratsioonid:

```sh
php artisan migrate
```

Väljund peaks olema järgmine:
```
Migration table created successfully.
Migrating: 2014_10_12_000000_create_users_table
Migrated:  2014_10_12_000000_create_users_table (0.01 seconds)
Migrating: 2014_10_12_100000_create_password_resets_table
Migrated:  2014_10_12_100000_create_password_resets_table (0.01 seconds)
Migrating: 2019_08_19_000000_create_failed_jobs_table
Migrated:  2019_08_19_000000_create_failed_jobs_table (0 seconds)

```

### 3.2 JSON & MariaDB

Kuna Zones on kasutusel MariaDB ning Laraveli enda sisene MariaDB draiver ei oska kõikide JSON funktsioonidega ringi käia (kasutatakse MySQL omast json path aliast), siis tuleb paigaldada MariaDB toe pakk.

Alates Laraveli versioonist 5.8 (mis ilmus 2019 alguses), pole seda enam vaja. Siiski võib seda vaja minna varasematel versioonidel ning seetõttu jätan selle info ka siia õpetusse. Kasutada saab seda ka 6.0 versiooniga ning kuna MariaDB's on teatud erinevusi, siis võib see tulla tulevikus kasuks:
https://github.com/laravel/framework/pull/25517

Paigaldame paki:

```sh
composer require ybr-nx/laravel-mariadb
```

Paki seadistamiseks muudame faili `config/database.php`. Otsime üles **mysql** ühenduse seaded ning asendame **driver** väärtuse **mariadb**'ga.

Tulemus peaks olema järgmine:
```
        // ...
        'mysql' => [
            'driver' => 'mariadb',
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '3306'),
            'database' => env('DB_DATABASE', 'forge'),
            'username' => env('DB_USERNAME', 'forge'),
        // ...
```


Testiks loome näiteks tabeli nimega **tasks**. Loome migratsiooni käivitades käsu:
```sh
php artisan make:migration create_tasks_table --create=tasks
```

Sellega loodi migratsioon ning faili näeb kaustas `database/migrations`. Migratsioonifaili nimes olev kuupäev on küll erinev, aga kolme faili seast peaks lihtne olema õiget valida. Juhendis loodud migratsiooni näite puhul muudame faili `database/migrations/2019_09_11_082935_create_tasks_table.php`

Muudame `up()` meetodit nii, et tulemus oleks järgmine
```php
//...
    public function up()
    {
        Schema::create('tasks', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->string('name');
            $table->json('information');
            $table->timestamps();
        });
    }
//...

```

Käivitame migratsiooni käsuga:
```sh
php artisan migrate
```

Tulemus peaks olema järgmine:
```
Migrating: 2019_09_11_082935_create_tasks_table
Migrated:  2019_09_11_082935_create_tasks_table (0.02 seconds)
```

Testime JSON väljade toimivust. Lisame `routes/web.php` faili sisu ruutingu, mis sisestab andmebaasi kirje ning kuvab selle kinnituseks ka kohe välja.

```php
//...
Route::get('/json', function () {
    DB::table('tasks')->insert([
        'name' => 'First task for me',
        'information' => json_encode([
            'location' => [
                'city' => 'Tallinn',
                'state' => 'Harjumaa',
                'todo' => 'Nothing'
            ]
        ])
    ]);
    dd(DB::table('tasks')->get());
}); 
//...
```

**NB!** Antud õpetuse skoobist väljudes tasub mainimist, et Eloquentis *array cast*'i kasutades pole Eloquent mudelitel *json_encode()* funktsiooni JSON väljadel tarvis kasutada.

Loodud kirje JSON kaudu pärimise testimiseks loome järgmise ruutingu faili `routes/web.php`:
```php
//...
Route::get('/jsonshow', function () {
    dd(DB::table('tasks')->where('information->location->city', '=', 'Tallinn')->get());
}); 
//...
```

Nüüd peaks URL ´https://laravel.miljonivaade.eu/jsonshow´ kuvama eelnevalt sisestatud kirjet.

Sellega on MariaDB seadistatud Laravel raamistikuga täisväärtuslikult töötama.

## 4. Redis (nõuab Virutaalserveri paketti II)

### 4.1 Redise seadistamine
Paigaldame **predis** paki käivitades rakenduse kaustas käsu:
```sh
composer require predis/predis
```

Muudame `.env` failis väärtused vastavalt `Virtuaalserveri Haldus` -> `Andmebaasid` -> `Redis` näidatavale:
```
REDIS_CLIENT=predis
REDIS_HOST=virtXXX.loopback.zonevs.eu
REDIS_PASSWORD=XXXXXXXX
REDIS_DB=0
REDIS_PREFIX=
```

Loome failis `routes/web.php` Redise testimiseks näidisruutingu:
```php
//...
Route::get('/redis', function () {
    dd(Redis::info());
}); 
//...
```
Kui nüüd aadressilt 'https://laravel.miljonivaade.eu/redis' vaatab vastu Redise info, peaks kõik toimima.

### 4.2 Redis ja sessioonid
Määrame rakenduse sessioone Redises hoidma. Selleks muudame `.env` failis `SESSION_DRIVER` väärtust.
```
SESSION_DRIVER=redis
```

### 4.3 Redis ja cache
Määrame rakenduse sessioone Redises hoidma. Selleks muudame `.env` failis `SESSION_DRIVER` väärtust.
```
SESSION_DRIVER=redis
```

Kui sessioone ja cache' hoida Redises, peab arvestama, et andmed ei säili pärast serveri ja redise taaskäivitamist. Enamasti see probleemiks ei ole. Kui on soov sessiooni TTL'i (*time to live*) pikendada ning et sessioonid säiliks, on mõtekam kasutada sessiooni `mysql` *driver*'it, mille seadistamine on kirjeldatud Laraveli dokumentatsioonis.

## 5. MongoDB (nõuab Virutaalserveri paketti II)

### 5.1 Seadistame MongoDB

**NB!** MongoDB ja Laravel 6.0 kooslus nõuab uut ZoneOS serveri platvormi. Oma serveri liigutamiseks uuele tuleb kirjutada info@zone.ee

https://help.zone.eu/kb/uleviimisel-uuele-zoneos-platvormile/

MongoDB ja Laraveli suhtluseks soovitame kasutada pakki **laravel-mongodb**
https://jenssegers.com/projects/laravel-mongodb

Kuna käsureal oleval PHP'l pole MongoDB PHP moodulit aktiveeritud, seadistame PHP CLI'le oma php.ini, kus laadime sisse mongodb mooduli. Selleks käivitame käsud:

```sh
cd ~
mkdir phpini-cli
echo "extension=php_mongodb.so" > phpini-cli/php.ini
echo "export PHP_INI_SCAN_DIR=/data01/virt75146/phpini-cli" >> ~/.bash_profile
export PHP_INI_SCAN_DIR=/data01/virt75146/phpini-cli
```

Paigaldame mongodb paki käivitades käsu **(NB! seda tuleb teha rakenduse juurkataloogis):**
```sh
composer require jenssegers/mongodb
```

Määrame vajalikud seaded, mis leiame lehelt `Virtuaalserveri Haldus` -> `Andmebaasid` -> `MongoDB`. Muudame `.env` failis väärtused:
```
MONGO_PORT=5678
MONGO_HOST=virtXXX.loopback.zonevs.eu
MONGO_DATABASE=mongodb_XXX
MONGO_USERNAME=mongodb_XXX
MONGO_PASSWORD=XXX
```

Kirjeldame MongoDB andmebaasi ühenduse raamistiku konfiguratsioonis, muutes faili `config/database.php`.

Lisame **connections** massiivi teiste elementide kõrvale järgneva:
```php
        //..
        'mongodb' => [
            'driver'   => 'mongodb',
            'host'     => env('MONGO_HOST', 'localhost'),
            'port'     => env('MONGO_PORT', 5678),
            'database' => env('MONGO_DATABASE'),
            'username' => env('MONGO_USERNAME'),
            'password' => env('MONGO_PASSWORD'),
            'options' => [
                'database' => env('MONGO_DATABASE')
            ]
        ],
        //..
```

Kindlasti tuleb tähelepanu pöörata 'options' sisule, kuna see määrab ära autentimise andmebaasi.

MongoDB testimiseks tekitame failis `routes/web.php` ruutingu:
```php
//...
Route::get('/mongodb', function () {
    dd(DB::connection('mongodb')->collection('users')->get());
}); 
//...
```
Külastame lehte 'https://laravel.miljonivaade.eu/mongodb'. Kui antud lehel kuvatakse tühja *collection'i* on see õigesti seadistatud

**Lisaks:**
Kui on soovi kasutada autentimise ja/või queue tarvis Moloquenti, leiab selle info Moloquenti dokumentatsioonist:
Autentimine: https://moloquent.github.io/master/#auth
Queue: https://moloquent.github.io/master/#queues

## 6. Queue
Queue käivitamiseks pole tingimata tarvis kõrgemat teenuspaketti kui I, kuid see on soovitatav, sest siis saab kasutada Queue käitamiseks Redist või MongoDB'd. MariaDB'i pidev koormamine ei mõju rakendusele hästi ning kui see jagatud keskonnas teisi segama hakkab, ei pruugi antud *worker* enam tööle jääda.

Antud näites paneme Queue tööle siiski MariaDB andmebaasi peal. Redise ja MongoDB kasutamiseks tuleb lihtsalt määrata vastav draiver **config/queue.php** konfiguratsioonifailis.

Täpsema info leiab dokumentatsioonist:
MySQL/MariaDB ja Redis: https://laravel.com/docs/6.0/queues
MongoDB: https://moloquent.github.io/master/#queues

Loome vajalikud andmebaasi tabelid:
```
php artisan queue:table
php artisan migrate
```

Määrame draiveriks andmebebaasi muutes failis `.env` väärtust:
```
QUEUE_CONNECTION=database
```

Draiverite seadistamine dokumentatsiooni järgi ei tohiks raskusi tekitada. Pigem tekib küsimus, et kuidas olla kindel, et queue töötaks, kui SSH'st välja logida ja kui serverile restart tehakse? Selleks tuleb Zones appi PM2.

Loome kõigepealt konfiguratsioonifaili `pm2.laravel.queue.json` sisuga:
```json
{
  "apps" : [{
    "name" : "laravel-queue",
    "cwd"  : "/data01/virt75146/domeenid/www.laravel.miljonivaade.eu/rakendus",
    "script" : "artisan",
    "interpreter" : "php",
    "args" : " queue:work",
    "max_memory_restart" : "128M"
  }]
}
```

Vajalikud seadistuste kirjeldused, mis tuleb seadistada vastavalt oma rakendusele:

| Väli | Kirjeldus |
| --- | --- |
| `apps.name` | Vabalt valitud nimi, mida kuvatakse PM2 halduses |
| `apps.cwd` | Täispikk rakenduse juurkataloogi asukoht |
| `apps.max_memory_restart` | Määrab kui suure mälu kasutuse korral rakendus taaskäivitatakse. Tuleb seadistada oma äranägemise järgi, aga kindlasti ei tohi see ületada paketis lubatut: https://www.zone.ee/et/virtuaalserver/vordlus. Kui on plaanis kasutada websocketeid, peab arvestama, et kõikide rakenduste kogumaht ei ületaks lubatut. |

Nüüd tuleb antud failist ka Zone platvormile teada anda:
`Virtuaalserver haldus` -> `Node.js ja PM2`, vajutada nuppu `Lisa uus Node.js rakendus`

Täida väljad:
**rakenduse nimi** : `laravel-queue` (võib olla vabalt valitud)
**skript või pm2 .json** : `domeenid/www.laravel.miljonivaade.eu/rakendus/pm2.laravel.queue.json` (.json faili asukoht alates `$HOME` kataloogist)

Mälukasutuse võib jätta 1MB peale, kuna see kirjutatakse .json failis üle.

Vajuta **Lisa** nuppu ning oota umbes 2 minutit. Queue toimivust saab kontrollida käsurealt käsuga:

```
pm2 list
```
või
```
pm2 show laravel-queue
```

Kui on soovi *queue*'t taaskäivitada, saab seda teha zone virutaalserveri halduses "ON/OFF" nupu kõrval oleva nupuga või käivita käsurealt vastav käsk:

```
php artisan queue:restart
```

## 7. Websockets (nõuab Virutaalserveri paketti III ning staatilist IP aadressi)
Websocketi ja PHP kooslus pole levinud nähtus ning selle seadistamine on olnud näidiste puudumise tõttu vaevaline. Õnneks on Laravel teinud suure töö ära **Laravel Echo** näol.

Kuna vaikimis on meil kõik pordid tulemüürist kinni või suunatud Apache peale, siis läheb sul pordi suunamiseks vaja staatilist IP-aadressi. Kui sul seda veel pole, saad selle tellida kirjutades klienditoele aadressil info@zone.ee.

Kui staatiline IP-aadress on olemas, veendume, et see on seadistatud vastavalt õpetusele punktis **1.4**.

Siinses õpetuses seadistame websocketite kasutamise **Redise** ning **Socket.IO** serveri abil. Redise paigaldamisest on meil juttu punktis number 4. Paigaldame peame veel Socket.IO serveri.

## 7.1 Laravel Echo Server
[GitHub - tlaverdure/laravel-echo-server: Socket.io server for Laravel Echo](https://github.com/tlaverdure/laravel-echo-server)

Meil on paigaldatud Let's Encrypt sertifikaat, kuid see paigaldatakse automaatselt ainult Apache veebiserverile ning selle proxy'le. Kuna EULA sertifikaatide privaatseid võitmeid jagada ei luba, tuleb siinkohal kasutada oma sertifikaate. Selleks on kolm võimalust:
* Tellida tasuline sertifikaat: [SSL sertifikaat - Zone.ee](https://www.zone.ee/et/turvalisus/ssl-sertifikaat/)
* Genereerida `self signed` sertifikaat
* Luua oma vahenditega Let's Encrypt sertifikaat kasutades DNS autoriseeringut ning Zone API't: [Let's Encrypt Node.JS rakendusega](https://github.com/zone-eu/docs/blob/master/articles/est/Lets-Encrypt-NodeJS.md)

Siinses juhendis eeldame, et üks neist on juba tehtud ning sertifikaat koos võtmega asub kataloogis `/data01/virt75146/certs`

Socket IO serveri paigaldame süsteemsele kasutajale globaalselt. Selleks liigume enne paigaldamist kodukataloogi.
```sh
cd ~
npm install laravel-echo-server
```

Liigume tagasi rakenduse juurkataloogi ning loome JSON konfiguratsioonifaili `laravel-echo-server.json`.

```
{
        "authHost": "https://laravel.miljonivaade.eu",
        "authEndpoint": "/broadcasting/auth",
        "database": "redis",
        "databaseConfig": {
                "redis": {
                    "database": 0,
                    "host": "virt75146.loopback.zonevs.eu",
                    "port": 6379,
                    "password": "XXX"
                }
        },
        "devMode": true,
        "host": null,
        "port": "6001",
        "protocol": "https",
        "socketio": {},
        "sslCertPath": "/data01/virt75146/certs/laravel.miljonivaade.eu.cert.pem",
        "sslKeyPath": "/data01/virt75146/certs/laravel.miljonivaade.eu.key.pem,
        "sslCertChainPath": "/data01/virt75146/certs/laravel.miljonivaade.eu.fullchain.pem",
        "sslPassphrase": "",
        "subscribers": {
                "http": true,
                "redis": true
        },
        "apiOriginAllow": {
                "allowCors": true,
                "allowOrigin": "https://laravel.miljonivaade.eu",
                "allowMethods": "GET, POST",
                "allowHeaders": "Origin, Content-Type, X-Auth-Token, X-Requested-With, Accept, Authorization, X-CSRF-TOKEN, X-Socket-Id"
        }
}
```

Seadete kirjeldused, mis tuleb seadistada vastavalt oma rakendusele:

| Väli | Kirjeldus |
| ---  | --- |
| `authHost` | Laraveli rakenduse avalik URL |
| `databseConfig.redis.database` | Redise andmebaasi number. Sama väärtus, mis `.env` failis muutujal `REDIS_DB` |
| `databseConfig.redis.host` | Virtuaalserveri *loopback* host |
| `databseConfig.redis.port` | Redise port, vaikeväärtuseks on meil **6379** |
| `databseConfig.redis.password` | Varem lisatud redise andmebaasi |
| `devMode` | Määrab ära, et echo serverist kasutatakse arendus keskonnas. **NB!** produktsioonis peab olemas selle väärtus **false** |
| `sslCertPath` | SSL sertifikaati path. Väärtus on erinev, kui see paigaldati teise asukohta, kui siinses õpetuses kirjeldatud |
| `sslCertPath` | SSL sertifikaati privaatse võtme. Väärtus on erinev, kui see paigaldati teise asukohta, kui siinses õpetuses kirjeldatud |
| `apiOriginAllow.allowOrigin` | Laraveli rakenduse avalik URL |

Ning käivitame testiks **laravel-echo-server** rakenduse
```
laravel-echo-server start
```

Ning töötav väljund peaks kuvama järgmist:
```
L A R A V E L  E C H O  S E R V E R

version 1.5.8

⚠ Starting server in DEV mode...

✔  Running at localhost on port 6001
✔  Channels are ready.
✔  Listening for http events...
✔  Listening for redis events...

Server ready!

```

Sulgeme rakenduse klahvikombinatsiooniga `ctrl + C` ning seadistame PM2 protsessihalduri seda jooksutama. Loome konfiguratsioon faili `pm2.laravel.echo.json` sisuga:

```json
{
  "apps" : [{
    "name" : "laravel-echo-server",
    "cwd"  : "/data01/virt75146/domeenid/www.laravel.miljonivaade.eu/rakendus",
    "script" : "laravel-echo-server",
    "args" : " start",
    "max_memory_restart" : "128M"
  }]
}
```

Tuletatavad väärtused võib asendada sarnaselt punktis **6** olevale PM2 konfiguratsioonifailile järgnevale tabelile.

Seadistame Virtuaalserveri halduses PM2 konfiguratsiooni, kus kõik toimub samuti sarnaselt punktile **6**, erinevad vaid väljade väärtused. `Virtuaalserver haldus` -> `Node.js ja PM2`, vajutada nuppu `Lisa uus Node.js rakendus`

**rakenduse nimi** : `laravel-echo-server` (võib olla vabalt valitud)
**skript või pm2 .json** : `domeenid/www.laravel.miljonivaade.eu/rakendus/laravel.echo.json`

Pärast rakendus lisandumist tuleb oodata umbes minut ning rakendust peaks nägema, kui käivitada käsk
```
pm2 show laravel-echo-server
```

Lisame info ka Laraveli rakenduse konfuguratsiooni. Muudame `.env` faili rea väärtust:
```
BROADCAST_DRIVER=redis
```

Failis `config/app.php` faili eemaldame kommentaari realt
```
App\Providers\BroadcastServiceProvider::class,
```

Seadistame portide suunamise, et websocket'iga laravel echo serverile ka ligi pääseks:
`Virtuaalserveri Haldus` -> `Veebiserver` -> `Portide Suunamine`

Lisame järneva:
* IP: varem hostile määratud staatiline IP
* Port: `6001`
* Kommentar: `laravel-echo-server` (vabalt valitud näidis)

Vajutame nuppu **Lisa** ning muudatused jõuavad serverini 10 minuti jooksul. Seni võib tegeleda järgmiste punktidega ning portide suunamist läheb vaja alles **7.1.3** juures vaja

## 7.1 Laravel Echo kliendi seadistamine ning testimine
Kuna näide põhineb privaatsel kanalil, tuleb enda rakenduses registreerida kasutaja ning sellega **sisse logida**. Kui kõik on tehtud nii, nagu õpetuses kirjas, saab seda kõike teha aadressil `https://laravel.miljonivaade.eu/register`

## 7.1.1 Loome kanali, kuhu me sõnumeid saatma hakkame
Kanali autentimiseks piisab sellest, kui muuta `routes/channels.php` faili sisu järgnevaks:

```php
<?php
use App\User;

Broadcast::channel('task.{task}', function (User $user, $task) {
    // lubame näidisrakenduses kõik ligi
    return true;
});
```

## 7.1.2 Loome näidis Event'i
```sh
php artisan make:event TaskAdded
```

Ning avame loodud faili `app/Events/TaskAdded.php` sisu järgnevaks:

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Queue\SerializesModels;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Broadcasting\PretaisenceChannel;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;

class TaskAdded implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $description;
    public $task;

    /**
     * Create a new event instance.
     *
     * @return void
     */
    public function __construct(int $task, string $description)
    {
        $this->description = $description;
        $this->task = $task;
    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return \Illuminate\Broadcasting\Channel|array
     */
    public function broadcastOn()
    {
        return new PrivateChannel('task.' . $this->task);
    }
}
```

Proovime event'i välja kutsuda ning loome näidisruutingu faili `routes/web.php`, mille sisuks on:

```php
Route::get('/sendtask', function () {
    event(new App\Events\TaskAdded(2, 'My second task todo.'));
    return 'Sent!';
}); 
```

Külastame aadressi `https://laravel.miljonivaade.eu/sendtask`. Kui kõik on õigesti seadistatud, peaks event jõudma `laravel-echo-server` rakenduse väljundisse, mida näeme pm2 logist:

```sh
tail -f /data01/virt75146/.pm2/logs/laravel-echo-server-out.log
```

## 7.1.3 Laravel Echo & Socket.IO JS kliendi seadistamine
Paigaldame vajalikud javascript teegid:
```sh
npm install --save laravel-echo socket.io-client
```

Lisame **Echo** frontend rakendusse. Avame faili `resources/js/bootstrap.js` ning lisame lõppu sinna järgnevad read:

```js
import Echo from "laravel-echo"

window.io = require('socket.io-client');

window.Echo = new Echo({
    broadcaster: 'socket.io',
    host: window.location.hostname + ':6001'
});
```

Muudame näidis Vue komponendis olevat `mountend()` meetodit järgnevalt:
```js
        mounted() {
            console.log('Component mounted.')

            Echo.channel('private-task.2')
            .listen('TaskAdded', (e) => {
                alert(e.description);
            });
        }
```

Kompileerime javascripti javascripti käsuga
```sh
npm run dev
```

Kui nüüd külastada lehte `https://laravel.miljonivaade.eu` ning brauseri teises kaardis avada URL `https://laravel.miljonivaade.eu/sendtask`, peaks esimesele kaardile tulema vastav javascripti alert.

## 8. Vue.JS & Hot Module Replacement (nõuab Virtuaalserveri paketti III ning staatilist IP aadressi)
Hot Module Replacement (HMR) on abimees arendajakogemuse parandamiseks. Iga arendaja on avastanud ennast olukorrast, kus iga javascriptis ja css'is tehtud muutuse pärast peab tulemuse nägemiseks brauseris lehe uuesti laadima. Hullemaks kipub olekord minema *one page application* puhul, kus tihtilugu peab soovitud seisundi saavutamiseks iga korda rakenduses edasi liikuma.  Arendades Laravel'i rakenduses UI'd Vue.JS'is, on võimalik vastav UI komponent automaatselt pärast muutmist laadida.

Eelduseks on SSL sertifikaadi olemasoleks vastavalt punktis **7.1** kirjeldatule

Seadistame portide suunamise, mille kaudu frontend rakendusega suhtleb:
`Virtuaalserveri Haldus` -> `Veebiserver` -> `Portide Suunamine`

Lisame järgneva:
* IP: varem hostile määratud staatiline IP
* Port: `6002`
* Kommentar: `laravel-hot-module-replace` (vabalt valitud näidis)

Muudame laraveli layouti kasutamaks mix'i. leiame failist `resources/views/layout.blade.php` rea
```html
<script src="{{ asset('js/app.js') }}" defer></script>
```
ning muudame selle järgnevaks:
```html
<script src="{{ mix('js/app.js') }}" defer></script>
```

Lisame faili `webpack.mix.js` algusesse pärast rida `const mix = require('laravel-mix');` järgmise:
```js
mix.options({
    hmrOptions: {
        host: 'laravel.miljonivaade.eu', //rakenduse domeen
        port: 6002 // portide suunamisel määratud port
    }
});
```

Seadistame **HMR** käima üle HTTPS'i. Selleks kasutame samu sertifikaate, mille punktis **7** echo serverile seadistasime. Seda teeme lisades faili `package.json` task'i `hot` lõppu *option*'id: `https`, `cert` ja `key`. Tulemuseks peaks olema järgmisele sarnanev rida:
```json
"hot": "cross-env NODE_ENV=development node_modules/webpack-dev-server/bin/webpack-dev-server.js --inline --hot --config=node_modules/laravel-mix/setup/webpack.config.js --https --cert=/data01/virt75146/certs/laravel.miljonivaade.eu.cert.pem --key=/data01/virt75146/certs/laravel.miljonivaade.eu.key.pem",
```

Käivitame arendustsüksli watch'i. Kasutades HMR'i, tuleb `watch` taski asemel lihtsalt käivitada `hot`
```sh
npm run hot
```

Avame URL'i `https://laravel.miljonivaade.eu`

Kui nüüd muuta näidiskomponendi `resources/js/components/ExampleComponent.vue` template'i, näeb muutust brauseris kohe.