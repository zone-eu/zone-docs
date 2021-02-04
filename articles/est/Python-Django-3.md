# Django 3 (Python) Zone.eu virtuaalserveris

Autor: [Ingmar Aasoja](https://github.com/ybr-nx) 

Antud õpetus on semi-official. Ehk annab suuna kätte, aga ametlike klienditoe kanalite kaudu tuge ei pakuta.

Õpetus eeldab, et on seadistatud SSH ligipääs. [SSH ühenduse loomine](https://help.zone.eu/kb/ssh-uhenduse-loomine/)

## 1. Virtualenv'i seadistamine

```
virtualenv ~/.venv/django-dev --python=python3.8
source ~/.venv/django-dev/bin/activate
```

## 2. Django paigaldamine ja seadistamine

```sh
pip install django==3.1
```

Loo projekt
```sh
cd domeenid/www.django.miljonivaade.eu
django-admin startproject miljonivaade
```

## 3. Andmebaasid

Kuna vaikimisi seadistatud sqllite3 pole Zone virtuaalsereris oleval pythonil toetatud (ja veebirakenduses ei ole ka kõige õigem valik), seadistame **MariaDB**

### 3.1.1 MariaDB

Kuna tavaline MariaDB/MySQL moodul vajab kompileerijat, siis peab Zone veebimajutuses kasutama selle asemel **PyMysql** moodulit, mis vajab veidi erinevat seadistamist. 

```
pip install pymysql
```

Seadista `miljonivaade/miljonivaade/settings.py` failis andmebaass järgnevalt:

```py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'HOST': 'dXXX.mysql.zonevs.eu', # andmebaasi serveri host
        'NAME': 'XXX', # andmebaasi nimi
        'PASSWORD': 'XXX', # andmebaasi salasõna
        'USER': 'XXX', # andmebaasi kasutajakonto
        'STRICT': True
    }
}
```

Ning selleks, et PyMySQL moodul töötaks pead muutma mõnda. Lisada tuleb `miljonivaade/manage.py` faili read:

```py
import pymysql

pymysql.install_as_MySQLdb()
```

Faili algus võiks näha välja umbes selline

```py
#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys
import pymysql # lisatud rida

pymysql.install_as_MySQLdb() # lisatud rida

def main():
#....
```

Sama pead lisama ka `miljonivaade/miljonivaade/wsgi.py` faili algusesse, mis võiks näha välja umbes selline:

```py
"""
WSGI config for miljonivaade project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/2.2/howto/deployment/wsgi/
"""

import os
import pymysql # lisatud rida

from django.core.wsgi import get_wsgi_application

pymysql.install_as_MySQLdb() # lisatud rida


```

### 3.2 Käivita migratsioonid

```
python miljonivaade/manage.py migrate
```

## 4. Seadistame serveri serveerimaks Django rakendust

### 4.1 Gunicorn ja Mod Proxy
Kuna Zone's mod_wsgi Apache moodulit ei ole, siis jääb ainukeseks võimaluseks kasutada **gunicorn** python moodulit ning serveerida seda läbi mod_proxy. Seadistame virtuaalserveri halduses soovitud domeeni/alamdomeeni mod_proxy port'i omale sobivaks. Antud juhul kasutame port'i **8000** - see on default, teisel juhul tuleb port määrata gunicorn'i käivitades optioniga `gunicorn --bind 0.0.0.0:8000`

Paigalda gunicorn

```
pip install gunicorn
```

**NB!** gunicorn tuleb paigaldada samaaegselt aktiveeritud virtenvis, siis see hoolitseb viimase aktiveerimise eest ise, kui seadistame **Pm2** teenust.

Ning käivita see
```sh
cd miljonivaade
gunicorn miljonivaade.wsgi:application
```

Kui nüüd brauseris külastada `https://django.miljonivaade.eu`, siis peaks seal kuvama veateaded, et antud host ei ole ALLOWED_HOSTS listis. See tähendab, et gunicorn töötab, aga vaja veel veidike seadistada Django rakendust

Lisa domeen ALLOWED_HOSTS list'i, ehk muuda fail `miljonivaade/miljonivaade/settings.py` umbes rea 28 ümber järgmiseks:

```py
ALLOWED_HOSTS = [
    'django.miljonivaade.eu'
]
```

Kui nüüd käivitada gunicorn uuesti, siis peaks brauser juba kuvama kenamat lehte teatega **The install worked successfully! Congratulations!**

Selleks, et server töötaks täisväärtuslikult, seadista gunicorn serveerima ka staatilisi faile. Muuda `miljonivaade/miljonivaade/urls.py` faili nii, et see näeks välja umbes järgmine:

```py
from django.contrib import admin
from django.urls import path

from django.contrib.staticfiles.urls import staticfiles_urlpatterns # lisatud rida

urlpatterns = [
    path('admin/', admin.site.urls),
]

urlpatterns += staticfiles_urlpatterns() # lisatud rida
```

Kui nüüd rakendust käivitada, siis brauser annab esilehel küll veateate, aga path'ile **/admin** minnes on pilt ilusam. 

### 4.2 Pm2 teenus

Et kindel olla rakenduse toimivuses pärast serveri taaskäivitamist ja/või mõne muu probleemi tekkimist, pead seadistama Pm2 teenuse.

Loo fail `miljonivaade/django.config.js` (faili nimi peab olema config.js laiendiga)

```js
module.exports = {
    apps : [{
        name : "django",
        cwd  : process.env.HOME + "/domeenid/www.django.miljonivaade.eu/miljonivaade",
        script : process.env.HOME + "/.venv/django-dev/bin/gunicorn",
        args: "miljonivaade.wsgi:application",
        interpreter: process.env.HOME + "/.venv/django-dev/bin/python3.8",
        max_memory_restart : "128M"
    }]
}
```

Järgmiseks tuleb see seadistada Minu Zone's

`virtuaalserveri haldus` -> `Veebiserver` -> `PM2 protsessid (Node.js)` 
Vajuta nuppu **Lisa uus Node.js rakendus**

| Väli | Kirjeldus | 
| --- | --- |
| **nimi** | django |
| **skript või PM2 .JSON** | /domeenid/www.django.miljonivaade.eu/miljonivaade/django.config.js |

Maksimaalse mälukasutuse võib jätta määramata. Vajuta nuppu **Lisa** ning mõne minuti jooksul peaks rakendus tööle hakkama. Kontrollida saad seda serveris käsuga `pm2 list`

## 5. Rakenduse arendamine

Django rakendust arendades on kood laetud mällu ning muutused ei kajastu kohe, selleks peab käsurealt taaslaadima rakenduse `--watch` parameetriga. Sel juhul jälgib Pm2 muudetavaid faile ning laeb vajadusel rakenduse uuesti.

```sh
pm2 start django --watch
```

Ning kui muudatused tehtud, siis lülita see välja
```sh
pm2 start django
```