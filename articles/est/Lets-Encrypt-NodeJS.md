## Let's Encrypt Node.JS rakendusega

Autor: [Ingmar Aasoja](https://github.com/ybr-nx)

Kuna Let's Encyrpt EULA ei luba jagada privaatseid võtmeid, siis Zone veebiserveri välises kontekstis peab sertifikaadi ise taotlema. /.well-know/acme-challenge URL on juba reserveeritud Zone enda tarvis ning ainuke variant on kasutada DNS autentimist. Selleks sobib väga hästi Acme.sh lihtne bash'i rakendus, millele on Zone.EU toe lisanud oma tänuväärse tööga [tambetliiv](https://github.com/tambetliiv).

Antud olukorras eeldan, et Node.JS rakenduseks on Virtuaalserveri kaudu lisatud rakendus, mille nimi on "laravel-echo server". Kui soovime kindlad olla, et läbi Minu Zone UI lisatud rakenduse nimi ikka vastab sellele, siis näeb hetkel töötavaid rakendusi käsuga:

```sh
pm2 list
```

Let's Encrypti sertifikaadi genereerimiseks DNS autoriseerimisega loo endale API ligipääs lisades Minu Zones API võtme: https://help.zone.eu/kb/zoneid-api-v2/

Seadista serveris api ligipääsu parameetrid:
```sh
cd ~
echo "export ZONE_Username={zone username}" >> ~/.bash_profile
echo "export ZONE_Key={zone api key}" >> ~/.bash_profile
source .bash_profile
```

Paigalda Acme.sh klient:
```sh
curl https://get.acme.sh | sh
mkdir -p bin
ln -s ~/.acme.sh/acme.sh ~/bin/acme.sh
```

Loo tühi kataloog `/data01/virt75146/certs` sertifikaatide hoidmiseks. (Node.JS) Rakendus tuleb panna kasutama sertifikaate samast kaustast.
```sh
mkdir /data01/virt75146/certs
```

Loo sertifikaat. Aega võib võtta see **kuni** 5 minutit:
```sh
acme.sh --issue -d laravel.miljonivaade.eu --dns dns_zone \
--cert-file      /data01/virt75146/certs/laravel.miljonivaade.eu.cert.pem  \
--key-file       /data01/virt75146/certs/laravel.miljonivaade.eu.key.pem  \
--fullchain-file /data01/virt75146/certs/laravel.miljonivaade.eu.fullchain.pem \
--reloadcmd "pm2 restart laravel-echo-server"
```

Skript ootab 5 minutit DNS kirje leviku taga. Kui skript töö lõpetab, on vajalikud sertifikaadifailid loodud ning taaskäivitatud ka vajalik Node.JS rakendus.

Selleks, et sertifikaat ka automaatselt uueneks, lisa antud rida Virtuaalserveri halduses `Veebiserver` -> `Crontab`. Intervalliks määra iga kuu vabalt valitud kuupäev, käivitusviis "süsteemselt" ning käsk järgmine:
```sh
source ~/.bash_profile && acme.sh --issue -d laravel.miljonivaade.eu --dns dns_zone --reloadcmd "pm2 restart laravel-echo-server"
```

