
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
 
## Deploiment 

### Fichier .env
creer un fichier **.env** qui doit se trouver dans le meme repoertoire que docker-compose.yml
Il contient votre environnement : 

``` 
CAS_HOSTNAME=https://cas.mondomain.com
LDAP_HOSTNAME=ldap://ildap.mondomaine.com:389
LDAP_SEARCH_FILTER=(&(uid={user})(objectclass=sogxuser))
LDAP_BASE=dc=mondamine,dc=com
LDAP_ATTRIBUTES_LIST=cn,givenName,mail,sn,uid,uid:username
LDAP_BIND_DN=CN=restreint,CN=internal,DC=mondomaine,DC=com
LDAP_BIND_CREDENTIAL=MonMotDePasse!

```
Ce fichier contient les variables d'environnement pour le container.

* CAS_HOSTNAME : c'est lde FDQN du serveur lui même (variable **cas.server.prefix** du fichier de configuration /etc/cas/config/cas.properties)
* LDAP_HOSTNAME : Adresse du serveur LDAP sous forme URI
* LDAP_SEARCH : filtre de recherche pour les utilisateur. Le nom d'utilisateur est representé par {user}. 
* LDAP_BASE : La base de recherche LDAP
* LDAP_ATTRIBUTES_LIST : la liste des attributs à renvoyer 
* LDAP_BIND_DN : le DN pour l authentification LDAP
* LDAP_BIND_CREDENTIAL : le mote de passe pour ce DN 

### Fichier docker-compose.yml
pour pouvoir rendre persistant les changements un volume doit pouvoir etre mappé. Si ce volume est vice le container créera automatiquement l'arborescense et les differents fichiers de configuration. 

```
version: "3"
services:
  cas-server:
    container_name: cas-server
    image: ghcr.io/libertech-fr/cas-docker:latest
    ports: 
      - "80:80"
      - "443:443"
    volumes: 
      - "./CAS:/etc/cas"
      - "./cert:/etc/cert"
      - "./logs:/data/logs"
    env_file: .env
```

Au premier demarrage le container va creer : 

* /etc/cas/config/cas.properties avec les variables d'environnement renseignées dans .env.
* /etc/cas/config/log4j2.xml
* /etc/cas/theme : le theme (css, js, images)
* /etc/cas/templates/custom : les modeles des pages html du serveur
* /etc/cas/saml : pour la signature des requetes saml

Une fois ces fichiers générés vous pouvez les modifier à volonté. Ils seront exploités par le container mais ils ne seront plus générés. 

## Volumes 
3 repertoires doivent être mappé : 
* /etc/cas : il contiendra la configuration, le thème et les modèles
* /etc/cert : il doit contenir les certificats (cert.pem, privkey.pem, chain.pem)
* /data/logs : il contient les journaux de tomcat et de cas 

## Personalisation
L'interface est entierement personalisable 
Apres le premier lancement un repertoire theme et templates ont été créé dans le volume /etc/cas
### Theme
* theme/css/cas.css : fichier css de personalisation de l'interface
* theme/images/mylogo.png : le logo qui apparaitra sur l'interface
* theme/images/facivon.icon : l'icône 

Une fois le thème changé vous devez le mettre à jour dans le container : 

```
#docker exec cas-server updatetheme
```

Vous pouvez revenir au thème par defaut avec ces commandes (cas-server etant le nom du container): 


```
#docker exec cas-server resettheme
#docker exec cas-server updatetheme
```

### Templates 
Les templates permettent de modifier des pages. Les headers, footer etc... se trouvent dans templates/custom/fragments
* Voir la documentation : (https://apereo.github.io/cas/6.6.x/ux/User-Interface-Customization-Themes.html#themed-views)

Une fois les fichiers modifiés vous devez les mettre à jour dans le container : 

```
#docker exec cas-server updatetemplates

```

Vous pouvez remettre les templates par défaut avec ces commandes : 


```
#docker exec cas-server resettemplates
```

# CAS modification de l'image 
Pour modifier l'image cloner ce dêpot

## Pour ajouter un module 
* Modifier le fichier **src/build.gradle** pour y inclure le dêpot (voir documentation de CAS)

## Pour modifier le fichier de configuration par défaut 
* fichier : **rootfs/data/rootfs/data/etc/cas.properties**

Remplacer dans docker-compose la ligne image par build: .



