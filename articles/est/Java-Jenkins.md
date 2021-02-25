# Jenkins Zone hallatud platvormil

Autor: [Ingmar Aasoja](https://github.com/ybr-nx) 

Antud õpetus on semi-official. Ehk annab suuna kätte, aga ametlike klienditoe kanalite kaudu tuge ei pakuta.

Õpetus eeldab, et on seadistatud SSH ligipääs. [SSH ühenduse loomine](https://help.zone.eu/kb/ssh-uhenduse-loomine/)

# 1. Loo Jenkinsi tarvis alamdomeen ning seadista proxy.

Kõige lihtsam on Jenkins paigaldada alamdomeenile nii, et selle veebiliides kuvatakse kasutajale Java serverist läbi veebiserveri proxy. Näiteks võid luua alamdomeeni nimega jeknins.sinudomeen.ee

Alamdomeeni lisamisel määra sellele mod_proxy sihtport 8080.

# 2. Paigalda java

Aadressilt https://java.com/en/download/manual.jsp kliki Linux x64 nimel parem klikk ja “Copy link address”, kasuta seda aadressi Java paki allalaadimiseks wget-i abil.

Käsureal käivitamiseks: (PS! See on näide ja paigaldab vana versiooni!)

```
cd ~/.zse/opt/oracle/java/
wget -O java.tar.gz https://javadl.oracle.com/webapps/download/AutoDL?BundleId=244058_89d678f2be164786b292527658ca1605
tar -zxf java.tar.gz
ln -sf jre1.8.0_281/bin bin
ln -sf jre1.8.0_281/lib lib
rm -f java.tar.gz
```

# 3. Paigalda Jenkins

Jenkinsi saab alla laadida aadressilt https://www.jenkins.io/download/. Valikus on LTS ning kõõige uuem stabiilne versioon. Vali endale sobib ning kopeera parekla hiireklõpsuga url. Zone platvormile tuleb valida **Generic jva package (.war)**, mis on nimekirjas kõige ülemine. Õpetuses kasutame kõige uuemat (mitte LTS) versiooni seisuga 20. veebruar 2021: https://get.jenkins.io/war/2.280/jenkins.war

```
mkdir -p ~/jenkins/home
cd ~/jenkins
wget https://get.jenkins.io/war/2.280/jenkins.war
```

Esmasel käviitamisel luuakse admin kasutaja, selleks teeme seda manuaalselt. **127.X.XX.XX** asemel tuleb kasutada käsu `vs-loopback-ip -4` väljundit

```
JENKINS_HOME=~/jenkins/home _JAVA_OPTIONS="-Djava.net.preferIPv4Stack=true -Djava.io.tmpdir=~/tmp" java -jar jenkins.war --httpListenAddress=127.X.XX.XX
```

Väljundis peaks olema ka kuvatud paigaldse salasõna

```
*************************************************************
*************************************************************
*************************************************************

Jenkins initial setup is required. An admin user has been created and a password generated.
Please use the following password to proceed to installation:

-XXXXXXXXXXXX-salasõna-XXXXXXXXXXXXXXX-

This may also be found at: /dataXX/virtXXX/jenkins/home/secrets/initialAdminPassword


*************************************************************
*************************************************************
*************************************************************
```

Nüüd navigeerime brauseris oma valitud (alam)domeenile. "https://jenkins.sinudomeen.ee" ning sisestame vormi eelnevalt kuvatud salasõna.

Kui on soov, siis järgmises vaates võib valida variandi valimaks ise vajalikke *pluginaid*.  Õpetuse raames valime **Install suggested plugins**.

Kui pluginad on paigaldatud, siis tuleb luua admin kasutaja. Täidame väljad ning vajutame nuppu **Save and Continue**. Järgmises vaates kuvab õnnestumise korral URL'i, millele Jenkins on paigaldatud. Seal tuleb vajutada **Save and Finish**

# 4. Seadistame Pm2

Kuna on tarvis, et Jenkins toimiks ka pärast serveri taaskäivitamist või taaskäivitaks ennast juhul, kui tekib süsteemne viga, siis tuleb seadistada Pm2 protsessihaldur. Killime jenkinsi protsessi vajutades consoolis `ctrl + c` ning loome uue faili `~/jenkins/jenkins.config.js` sisuga:

**NB!** asenda **127.X.XX.XX** käsu `vs-loopback-ip -4` väljundiga

```
module.exports = {
    apps : [{
        name : "jenkins",
        script : process.env.HOME + "/.zse/opt/oracle/java/bin/java",
        cwd : process.env.HOME + "/jenkins/",
        args: "-jar jenkins.war --httpListenAddress=127.X.XX.X",
        max_memory_restart : "4G",
        env: {
            "JENKINS_HOME": process.env.HOME + "/jenkins/home",
            "_JAVA_OPTIONS": "-Djava.net.preferIPv4Stack=true -Djava.io.tmpdir=" + process.env.HOME + "/tmp -Xms64M -Xmx2G"
        }
    }]
}
```

Mine MinuZone haldusliidesesse punkti alla `Veebiserver` -> `PM2 protsessid (Node.js)` ning vajuta nuppu  **Lisa uus rakendus**
Rakenduse nimi pane **Jenkins.**
Skript või PM2 .JSON lahtrisse sisesta **jenkins/jenkins.config.js**
Maksimaalne mälukasutus **1MiB**

Vajuta nuppu **Salvesta muudatused**

Nüüd peaks mõne minut pärast Jenkis käivituma. Käsk `pm2 monit` monitoorib aktiivseid rakenduse ning annab teada, kui Jenkins on käivitatud
