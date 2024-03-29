
# CAS Out of the box
## Description 
Cette image a pour but de fournir au administrateurs un serveur CAS facile à mettre en place. En effet la compilation et la configuration du serveur CAS Apereo n'est pas évidente sans connaissance profonde des protocoles d'authentification et de l'environnement JAVA

L'image Docker a été conçue pour que l'aspect et le paramêtrage soient aisés. 

Elle embarque les protocoles suivant : 

* LDAP
* OIDC (OpenId connect) (https://apereo.github.io/cas/6.6.x/authentication/OIDC-Authentication.html) 
* SAMLv2 (https://apereo.github.io/cas/6.6.x/authentication/Configuring-SAML2-Authentication.html) 
* SAMLv1 (https://apereo.github.io/cas/6.6.x/protocol/SAML-Protocol.html) 

D'autre protocoles seront ajoutés dans des versions ultérieures comme le MFA. 

**Si les repertoires de configuration n'existent pas le container se servira des variables d'environnement pour les créer**
 
## Deploiement 

### Fichier .env
créer un fichier **.env** qui doit se trouver dans le meme répertoire que docker-compose.yml
Il contient votre environnement : 

``` 
CAS_HOSTNAME=https://cas.mondomain.com
CAS_URI=/cas
LDAP_HOSTNAME=ldap://ldap.mondomaine.com:389
LDAP_SEARCH_FILTER=(&(uid={user})(objectclass=sogxuser))
LDAP_BASE=dc=mondomaine,dc=com
LDAP_ATTRIBUTES_LIST=cn,givenName,mail,sn,uid,uid:username
LDAP_BIND_DN=CN=restreint,CN=internal,DC=mondomaine,DC=com
LDAP_BIND_CREDENTIAL=MonMotDePasse!

```
Ce fichier contient les variables d'environnement pour le container.

* CAS_HOSTNAME : c'est lde FDQN du serveur lui même (variable **cas.server.name** du fichier de configuration /etc/cas/config/cas.properties)
* CAS_URI : l Uri du serveur (ex: /cas)
* LDAP_HOSTNAME : Adresse du serveur LDAP sous forme URI
* LDAP_SEARCH : filtre de recherche pour les utilisateurs. Le nom d'utilisateur est representé par {user}. 
* LDAP_BASE : La base de recherche LDAP
* LDAP_ATTRIBUTES_LIST : la liste des attributs à renvoyer 
* LDAP_BIND_DN : le DN pour l authentification LDAP
* LDAP_BIND_CREDENTIAL : le mote de passe pour ce DN 

### Fichier docker-compose.yml
pour pouvoir rendre persistant les changements un volume doit être mappé. Si ce volume est vide le container créera automatiquement l'arborescense et les différents fichiers de configuration. 

```
version: "3"
services:
  cas-server:
    container_name: cas-server
    image: ghcr.io/libertech-fr/cas-docker:latest
    network_mode: "host"
    restart: always 
    volumes: 
      - "./etc:/etc/cas"
      - "./cert:/etc/cert"
      - "./logs:/data/logs"
    env_file: .env
```

Au premier demarrage le container va creer : 

* /etc/cas/config/cas.properties avec les variables d'environnement renseignées dans .env.
* /etc/cas/config/log4j2.xml
* /etc/cas/themes/custom : le theme custom (css, js, images)
* /etc/cas/themes/custom.properties : Le fichier paramètre du theme custom
* /etc/cas/templates/custom : les modeles des pages html du theme custom
* /etc/cas/saml : pour la signature des requetes saml

Une fois ces fichiers générés vous pouvez les modifier à volonté. Ils seront exploités par le container mais ils ne seront plus générés. 

A NOTER : le theme s'appelle **"custom"**

## Volumes 
3 repertoires doivent être mappés : 
* /etc/cas : il contiendra la configuration, le thème et les modèles.
* /etc/cert : il doit contenir les certificats (cert.pem, privkey.pem, chain.pem)
* /data/logs : il contient les journaux de tomcat et de cas 

## Personalisation
L'interface est entierement personalisable.
Apres le premier lancement un repertoire themes et templates ont été créé dans le volume /etc/cas
### Theme
* themes/custom/css/cas.css : fichier css de personalisation de l'interface
* themes/custom/images/mylogo.png : le logo qui apparaitra sur l'interface
* themes/custom/images/facivon.icon : l'icône 
* themes/custom/custom.properties : Le fichier de configuration du theme

Une fois le thème changé vous devez le mettre à jour dans le container : 

```
#docker exec cas-server updatethemes
```

Vous pouvez revenir au thème par defaut avec ces commandes (cas-server etant le nom du container): 


```
#docker exec cas-server resetthemes
#docker exec cas-server updatethemes
```
ou en commentant la variable **cas.theme.default-theme-name=custom** dans le fichier cas-properties

### Templates 
Les templates permettent de modifier des pages. Les headers, footer etc... se trouvent dans **templates/custom/fragments**

* Voir la documentation : (https://apereo.github.io/cas/6.6.x/ux/User-Interface-Customization-Themes.html#themed-views)

Une fois les fichiers modifiés vous devez les mettre à jour dans le container : 

```
#docker exec cas-server updatetemplates

```

Vous pouvez remettre les templates par défaut avec ces commandes : 


```
#docker exec cas-server resettemplates
```

# CAS interface d'administration 
L'interface d'administration est accessible par CAS_HOSTNAME/cas-management

## Comptes pouvant y avoir acces 
Modifier le fichier etc/config/admin-users.json. Mettre l'id CAS (le login) à la place de casuser.

ATTENTION : Pour l'instant l'interface est mise à titre de tests


## Protection par IP de l'Url de management
Creer un fichier **context.xml** 


``` 
<Context>
    <Valve className="org.apache.catalina.valves.RemoteIpValve" />
    <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="10\.0\.0\.5$" />
</Context>
``` 

l'attribut allow est une expression regulière (voir doc tomcat)

Ajouter dans docker-compose.yml un volume 

```
- "./context.xml:/usr/local/tomcat/webapps/cas-management/META-INF/context.xml"
```


# CAS modification de l'image (Pour les developpeur)
NOTE : **Cette parite n'est pas necessaire pour mettre en production**

Vous devez avoir git et docker installés sur la machine.

Pour modifier l'image cloner ce dêpot.

## Pour ajouter un module 
* Modifier le fichier **src/build.gradle** pour y inclure le dêpot (voir documentation de CAS)

## Pour modifier le fichier de configuration par défaut 
* fichier : **rootfs/data/rootfs/data/etc/cas.properties**

Remplacer dans docker-compose la ligne image par build: .



