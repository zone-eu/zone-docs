# Django 2 (Python) Zone.eu virtuaalserveris

Autor: [Ingmar Aasoja](https://github.com/ybr-nx) 

[Antud õpetus on aegunud! Django 3 leiad siit](./Python-Django-3.md)

Antud õpetus on semi-official. Ehk annab suuna kätte, aga ametlike klienditoe kanalite kaudu tuge ei pakuta.

Õpetus töötab ainult alates uuest ZoneOS platvormi versioonist 19.10.00. Seda saad kontrollida nii:
```
cat /etc/os-release | grep PRETTY_NAME
```

## 1. Virtualenv'i seadistamine

```
virtualenv ~/.venv/django-dev --python=python3.6
source ~/.venv/django-dev/bin/activate
```

## 2. Django paigaldamine ja seadistamine

Valitud on verioon 2.1 kuna 2.2 ei toeta PyMySQL moodulit. (Vaata antud õpetuse punkti **6**)

```sh
pip install django==2.1
```

Loo projekt
```sh
cd domeenid/www.django.miljonivaade.eu
django-admin startproject miljonivaade
```

## 3. Andmebaasid

Kuna vaikimisi seadistatud sqllite3 pole Zone virtuaalsereris oleval pythonil toetatud (ja veebirakenduses ei ole ka kõige õigem valik), peab seadistama muu andmebaasi. Valikuks on **MariaDB** ja **MongoDB**. 

### 3.1.1 MariaDB

Kuna tavaline MariaDB/MySQL moodul vajab kompileerijat, siis kasuta sellleks **PyMysql** moodulit, mis vajab veidi erinevat seadistamist. 

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
import pymysql

pymysql.install_as_MySQLdb()

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
import pymysql

from django.core.wsgi import get_wsgi_application

pymysql.install_as_MySQLdb()


```

### 3.1.2 MongoDB

Paigalda **djongo** (MonoDB django moodul)

```
pip install djongo
```

Seadista `miljonivaade/miljonivaade/settings.py ` failis andmebaas järgnevalt:

```py
DATABASES = {
     'default' : {
        'ENGINE': 'djongo',
        'ENFORCE_SCHEMA': True,
        'NAME': 'mongodb_XXX', # MongoDB andmebaas
        'USER': 'mongodb_XXX', # MongoDB kasutajanimi
        'PORT': 5678,
        'PASSWORD': '{XXX}', # MongoDB parool
        'HOST': 'virtXXX.loopback.zonevs.eu', # MongoDB host
        'AUTH_SOURCE': 'admin'

    }
}
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
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
ö
urlpatterns = [
    path('admin/', admin.site.urls),
]

urlpatterns += staticfiles_urlpatterns()
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
        interpreter: process.env.HOME + "/.venv/django-dev/bin/python3.6",
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
| **skript või PM2 .JSON** | miljonivaade/django.config.js |

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

## 6. Django 2.2 ja PyMysql

Kuna PyMySQL'il on veel kompatiilsusprobleeme Djangoga 2.2 versiooniga, siis peab muutma mõnda faili. Neid tuleb teha iga kord, kui paigaldatakse antud pakk pip'iga. Kui antud *issue* lahendatakse, siis täiendan õpetust.
https://github.com/PyMySQL/PyMySQL/issues/790

Parandatud **PyMySQL** tugi peaks jõudma Django 3.0 versiooni
https://code.djangoproject.com/wiki/Version3.0Roadmap

Kui on soov paigaldada uuem django, siis [Django 3 õpetuse leiad siit.](./Python-Django-3.md)

Django 2.2 puhul pead tegema järgmised muutused

`~/.venv/django-dev/lib64/python3.6/site-packages/django/db/backends/mysql/base.py`
Rida 35 muuda
```py
if version < (1, 3, 12):
```

`~/.venv/django-dev/lib64/python3.6/site-packages/django/db/backends/mysql/operations.py`
Rida 146 muuda

```py
query = query.encode(errors='replace')

```