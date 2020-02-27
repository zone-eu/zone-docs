# Gitea – Alternatiiv GitHubile, mis töötab Zone Virtuaalserveris

## Mis on Gitea?

Autor: [Ingmar Aasoja](https://github.com/ybr-nx)

Gitea on GO’s kirjutatud avatud lähtekoodiga alternatiiv populaarsetele versioonihaldusteenustele Github ja Gitlab. Täpsemat infot Gitea kohta leiad aadressilt [https://gitea.io/](https://gitea.io/) ning põhjaliku dokumentatsiooniga saab tutvuda siin: [https://docs.gitea.io/en-US/](https://docs.gitea.io/en-US/)

![Gitea logo](https://blog.zone.ee/static/sites/2/2018/06/gitea.001.png)

## Nõuded Zone teenusele

Kasutusel peab olema Zone tarkvaraplatvormi kasutav server (kõlbab nii Virtuaalserver, Nutikas Pilveserver kui ka Nutikas Privaatserver). Käesolevas õpetuses on virtuaalserveri nimeks **git.miljonivaade.eu**

**Virtuaalserveril peab olema eraldatud IP aadress portide suunamise tarvis. Pakett III sisaldab ühte tasuta eraldatud IP aadressi. Kui see aktiveeritud pole, tuleb ühendust võtta Zone klienditoega, kes selle tasuta aktiveerib.**

## 1. Seadistame Zone virtuaalserveri

### 1.1 SSH

Kui teil on juba SSH ligipääs virtuaalserverile seadistatud võib jätkata punktist **1.2**

**Virtuaalserveri Haldus -> SSH -> Ligipääs**

*   Lisame oma avaliku SSH võtme
*   Lubame ligipääsu oma IP aadressilt (või kõikjalt)

### 1.2 MySQL

**Virtuaalserveri Haldus -> Andmebaasid -> MySQL**

*   Lisame uue andmebaasi nimega **d73643_gitea**. Collation väljale valime **utf8mb4_general_ci**
*   Lisame uue kasutaja nimega **d73643_gitea**
*   Anname kasutajale **d73643_gitea** kõik õigused andmebaasis **d73643_gitea**

### 1.3 HTTP ligipääsu seadistamine (http proxy)

**Virtuaalserveri Haldus -> Veebiserver -> Seaded** HTTPS seadete all vajutame nuppu **muuda**

*   SSL/VHosti IP: **XXX.XXX.XXX.XXX**, mille väätuseks on virtuaalserverile eraldatud IP aadress.
*   Määrame mod_proxy sihtpordiks **3000**
*   Ning vajutame **Salvesta muudatused** nuppu

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-2-1024x862.png)

### 1.4 Gitea SSH ligipääsu seadistamine GITile (portide suunamine)

Gitea kasutab oma sisest SSH serverit, mis annab võimaluse git repositooriumite ning kasutajate ligipääse Giteas endas hallata.

**Virtuaalserveri Haldus -> Veebiserver -> Portide Suunamine**

*   Lisa uus portide suunamine all tuleb täita väljad
    *   IP: Valime Zone poolt eraldatud IP aadressi
    *   Port: **2222**
    *   Kommentaar: **gitea-ssh** (vabalt valitud näidis)
    *   Ning vajutan nuppu **Lisa**

_**HTTP proxy ja portide suunamise muudatused jõuavad serverisse umbes 10 minuti jooksul, aga DNS A kirje levimine eraldatud IP aadressile võib võtta ka üle tunni. Kui on soov rakendus enne kirjete levimist seadistada, siis võib IP enda tööjaama hosts faili lisada.**_

## 2. Paigaldame Gitea

### 2.1 Laadime alla ning paigaldame Gitea binaarfaili

Siseneme virtuaalserverisse SSH abil ning käivitame järgmised read:
```sh
    mkdir domeenid/www.git.miljonivaade.eu/gitea
    cd domeenid/www.git.miljonivaade.eu/gitea
    wget -O gitea https://dl.gitea.io/gitea/1.9.6/gitea-1.9.6-linux-amd64
    chmod +x gitea
```
Et Gitea esialgse konfiguratsioonifaili genereeriks, tuleb gitea korraks käivitada. Antud juhul see ebaõnnestub, aga tekitatakse **custom/conf/app.ini** fail.

Käivitame käsu:
```sh
    ./gitea web
```
Tulemus peaks olema järgmine:

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-9-1024x181.png)

### 2.2 Seadistame rakenduse konfiguratsioonid

Avame konfiguratsioonifaili
```sh
    nano custom/conf/app.ini
```
Kogu sisu tuleb üle kirjutada järgnevaga:
```ini
    RUN_USER = virt73403
    RUN_MODE = prod

    [database]
    DB_TYPE = mysql
    HOST = d73643.mysql.zonevs.eu:3306
    USER = d73643_gitea
    NAME = d73643_gitea

    [repository]
    ROOT = /data03/virt73403/domeenid/www.git.miljonivaade.eu/gitea/repositories

    [server]
    PROTOCOL = http
    DOMAIN = git.miljonivaade.eu
    HTTP_ADDR = 127.1.69.203
    HTTP_PORT = 3000
    DISABLE_SSH      = false
    START_SSH_SERVER = true
    SSH_PORT = 2222
    SSH_LISTEN_HOST = 127.1.69.203

    [log]
    MODE      = file
    LEVEL     = Info
    ROOT_PATH = /data03/virt73403/domeenid/www.git.miljonivaade.eu/gitea/log
```
Virtuaalserveri põhised muutujad konfiguratsioonis:

*   **RUN_USER** – kasutaja, kelle õigustes rakendus käivitatakse. Selleks on virtuaalserveri SSH kasutajanimi.
*   **database.HOST** – andmebaasi hosti nimi, mille leiab Virtuaalserver Haldus -> Andmebaasid -> MySQL alampunktist. Lisaks tuleb määrata port, milleks on 3306.
*   **database.USER** – loodud MySQL kasutaja kasutajanimi.
*   **database.NAME** – loodud andmebaasi nimi.
*   **repository.ROOT** – asukoht, kuhu pannakse loodud repositooriumite andmed. Selle peaks määrama kujul: /dataXX/{ssh-kasutaja}/domeenid/[www.{domeen}/vabalt/valitud/asukoht](http://www.%7Bdomeen%7D/vabalt/valitud/asukoht)
*   **server.PROTOCOL** – konfiguratsioonis määrame protokoliks “http”, kuna HTTPS eest hoolitseb Zone seadistatud proxy.
*   **server.DOMAIN** – virtuaalserveri nimi ehk domeen.
*   **server.HTTP_ADDR** – virtuaalserveri loopback IP, mille saab teada kui käivitada virtuaalserveris SSH konsoolis käsk **vs-loopback-ip -4**.
*   **server.HTTP_PORT** – port, mille määrasime mod_proxy pordiks serveri seadetes.
*   **server.SSH_PORT** – port, mille määrasime portide suunamisel.
*   **server.SSH_LISTEN_HOST** – sama mis **server.HTTP_ADDR**.
*   **log.ROOT_PATH** – logifailide kataloog, mille võib määrata järgmiselt: /dataXX/{ssh-kasutaja}/domeenid/[www.{domeen}/vabalt/valitud/asukoht](http://www.%7Bdomeen%7D/vabalt/valitud/asukoht)

### 2.3 Paigaldame ning käivitame rakenduse

Pärast seda käivitame rakenduse uuesti
```sh
    ./gitea web
```
Ning kui kõik õnnestub, peaks pilt välja selline:

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-1.png)

Veebiliides peaks tööle hakkama minnes aadressile: [https://git.miljonivaade.eu](https://git.miljonivaade.eu/) ning avanema peaks järgmine pilt:

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-3-1024x748.png)

Põhikonfiguratsioon on sellega paigas. Antud lehel tuleb siis lisaks

*   sisestada MySQL kasutaja parool
*   kustutada pordi number **Application URL** väärtusest ning scheme määrata HTTPS. Antud juhul on lõppväärtus [https://git.miljonivaade.eu/](https://git.miljonivaade.eu/)

Lõplikuks paigaldamiseks vajutame nuppu **Install Gitea**.

Õnnestunud paigalduse korral peaks avanema järgmine pilt:

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-4-1024x447.png)

Selles vaates tuleb teha endale konto. Esimesena registreeritud kontole antakse ka administraatori õigused.

_**Selle alampunkti lõpuks on meil olemas täisväärtuslik töötav Gitea rakendus. Nüüd on vaja lisada seaded, et Zone oskaks seda vajadusel automaatselt käivitada ja/või restartida**_

## 3. Seadistame Zone virtuaalserveri töötamaks Giteaga

### 3.1 Seadistame Gitea teenuse PM2’s

Kui Gitea töötab, peatame rakenduse klahvikombinatsiooniga **ctrl + c**.

Järgmiseks tuleb seadistada PM2, et Gitea jätkaks tööd ka pärast SSH’st välja logimist ning pärast Zone poolset serveri taaskäivitust. Selleks lisame PM2 teenuse. Samuti aitab PM2 rakendust automaatselt taaskäivitada, kui mingi probleemi tõttu peaks see “maha surema”.

Tekitame PM2 konfiguratisoonifaili:
```sh
    nano /data03/virt73403/domeenid/www.git.miljonivaade.eu/gitea/gitea-pm2.json
```
Faili sisu peab olema selline:
```json
    {
     "apps" : [{
     "name" : "gitea-service",
     "script" : "gitea",
     "cwd" : "/data03/virt73403/domeenid/www.git.miljonivaade.eu/gitea",
     "args" : "web"
     }]
    }
```
Salvestame faili ning Virtuaalserveri haldusliideses lisame rakenduse:

**Virtuaalserveri Haldus -> Veebiserver -> Node.js ja PM2**

*   Vajutame nuppu “Lisa uus Node.js rakendus”
*   Täidame väljad
    *   Rakenduse nimi: **gitea-service** (vabalt valitud näids)
    *   Skript või pm2.json: **domeenid/[www.git.miljonivaade.eu/gitea/gitea-pm2.json](http://www.git.miljonivaade.eu/gitea/gitea-pm2.json)**
    *   Maksimaalne mälukasutus: kuna .json faili puhul see seade mõju ei avalda, võib see jääda 1MB peale.
*   Vajutame **Lisa** nuppu

Rakenduse käivitamiseks läbi PM2 peame ootama paar minutit. Veendumaks, et rakendus toimib, proovime selle aja möödudes minna brauseris rakenduse vaatesse – [https://git.miljonivaade.eu/](https://git.miljonivaade.eu/).

Kui antud aadressil avaneb Gitea rakendus, võib kontrollida, et rakendus sai ikka PM2 poolt käivitatud. Seda saab teha SSH konsoolis käsuga
```sh
    pm2 status
```
Avaneda võiks järgmine pilt:

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-5.png)

## 4. Hakkame rakendust kasutama ja/või testima

Järgnev tekst on juba töötava rakenduse näide, kui esimene kasutajakonto on loodud. Gitea on Zone virtuaalserveris paigaldatud, seadistatud õigesti käivituma ning järgnev on pigem väga lühike sissejuhatus rakendusse esimese repositooriumi loomiseks ning giti SSH ligipääsu seadistamiseks.

### 4.1 Sisestame SSH avaliku võtme git ligipääsuks

*   Klikime paremal üleval ikoonil ning avame menüüpunkti **Your Settings**
*   Avanenud lehel avame kaardi **SSH / GPG Keys**
*   SSH võtme all vajutame nuppu **Add key**

### 4.2 Loome uue respositooriumi

Siseneme **Dashboard** vaatesse. Visuaalne pilt on sarnane Githubi ja Gitlabiga ning neid kasutanud ei tohiks ka siin repositooriumi seadistamisega hätta jääda.

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-6.png) ![](https://blog.zone.ee/static/sites/2/2018/06/gitea-7.png)

### 4.3 Hakkame kasutama

Repositooriumi vaates **Clone this repository** alt tuleb valida **SSH** ning kopeerida vastav URL.

Näiteks
```sh
    git clone ssh://virt73403@git.miljonivaade.eu:2222/ingmar/zone-test.git
    touch README.md
    git add .
    git commit -m "added readme"
    git push
```
Ning giti kasutanud inimesel ei tohiks olla raske veenduda, et kõik töötab.

![](https://blog.zone.ee/static/sites/2/2018/06/gitea-8-1024x354.png)

Edasi tuleb vaid Giteaga lähemat tutvust sobitada ning see enda vajaduste järgi ära seadistada.