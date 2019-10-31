# Let's Encrypt genereerimine Lego kliendiga

Autor: [Ingmar Aasoja](https://github.com/ybr-nx)

https://go-acme.github.io/lego/dns/zoneee/

Paigalda lego
```sh
wget https://github.com/go-acme/lego/releases/download/v3.1.0/lego_v3.1.0_linux_amd64.tar.gz
tar -xvf lego_v3.1.0_linux_amd64.tar.gz
mv lego bin/lego
```

Seadista API klient
```sh
export ZONEEE_API_USER={zone username}
export ZONEEE_API_KEY={zone api key}
echo "export ZONEEE_API_USER={zone username}" >> ~/.bash_profile
echo "export ZONEEE_API_KEY={zone api key}" >> ~/.bash_profile
```

Loo kasutaja ja sertifikaat. Esimesel käivitusel pead kinnitama, et oled tutvunud kasutajatingimustega.

```sh
lego --email example@example.org --dns zoneee --domains laravel.miljonivaade.eu run
```

Väljund on umbes selline:
```
2019/10/30 19:34:33 No key found for account example@example.org. Generating a P384 key.
2019/10/30 19:34:33 Saved key to /data01/virtXXXXX/.lego/accounts/acme-v02.api.letsencrypt.org/example@example.org/keys/example@example.org.key
2019/10/30 19:34:33 zoneee: some credentials information are missing: ZONEEE_API_USER,ZONEEE_API_KEY
2019/10/30 19:34:33 Please review the TOS at https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf
Do you accept the TOS? Y/n
Y
2019/10/30 19:34:38 [INFO] acme: Registering account for example@example.org
!!!! HEADS UP !!!!

                Your account credentials have been saved in your Let's Encrypt
                configuration directory at "/data01/virtXXXXX/.lego/accounts".
                You should make a secure backup of this folder now. This
                configuration directory will also contain certificates and
                private keys obtained from Let's Encrypt so making regular
                backups of this folder is ideal.2019/10/30 19:34:38
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] acme: Obtaining bundled SAN certificate
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] AuthURL: https://acme-v02.api.letsencrypt.org/acme/authz-v3/1010758337
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] acme: Could not find solver for: tls-alpn-01
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] acme: Could not find solver for: http-01
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] acme: use dns-01 solver
2019/10/30 19:35:10 [INFO] [laravel.miljonivaade.eu] acme: Preparing to solve DNS-01
2019/10/30 19:35:11 [INFO] [laravel.miljonivaade.eu] acme: Trying to solve DNS-01
2019/10/30 19:35:11 [INFO] [laravel.miljonivaade.eu] acme: Checking DNS record propagation using [217.146.66.66:53 217.146.66.65:53 194.204.49.1:53 90.191.225.242:53]
2019/10/30 19:35:11 [INFO] Wait for propagation [timeout: 5m0s, interval: 5s]
2019/10/30 19:35:11 [INFO] [laravel.miljonivaade.eu] acme: Waiting for DNS record propagation.
2019/10/30 19:35:16 [INFO] [laravel.miljonivaade.eu] acme: Waiting for DNS record propagation.
.....
2019/10/30 19:36:31 [INFO] [laravel.miljonivaade.eu] acme: Waiting for DNS record propagation.
2019/10/30 19:36:42 [INFO] [laravel.miljonivaade.eu] The server validated our request
2019/10/30 19:36:42 [INFO] [laravel.miljonivaade.eu] acme: Cleaning DNS-01 challenge
2019/10/30 19:36:43 [INFO] [laravel.miljonivaade.eu] acme: Validations succeeded; requesting certificates
2019/10/30 19:36:43 [INFO] [laravel.miljonivaade.eu] Server responded with a certificate.
```

Sertifikaadid asuvad kaustas `~./lego/certificates/`

Uuendamiseks lisa süsteemne cron:

```sh
source ~/.bash_profile && lego --email example@example.org --dns zoneee --domains laravel.miljonivaade.eu renew --renew-hook "pm2 restart laravel-echo-server"
```