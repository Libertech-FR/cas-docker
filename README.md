
# CAS Out of the box
## Description 
Cette image a pour but de fournir au administrateurs un serveur CAS facile à mettre en place. En effet la compilation et la configuration du serveur CAS Apereo n'est pas évidente sans connaissance profonde des protocoles d'authentification et de l'environnement JAVA

L'image Docker a été conçue pour que l'aspect et le paramêtrage soient aisés. 

Elle embarque les protocoles suivant : 
* LDAP
* OIDC (Oauth, openId)
* SAML (saml1, saml2)

D'autre protocoles seront ajoutés dans des versions ultérieures comme le MFA. 
 
## Deployment 

### Fichier .env
creer un fichier **.env** qui doit se trouver dans le meme repoertoire que docker-compose.yml
Il contient votre environnement : 

``` 
CAS_HOSTNAME=https://cas.mondomain.com
LDAP_HOSTNAME=ldap://ildap.mondomaine.com:389
LDAP_SEARCH_FILTER="(&(uid={user})(objectclass=sogxuser))"
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
    build: ghcr.io/libertech-fr/cas-docker:latest
    ports: 
      - "80:80"
  - "443:443"
    volumes: 
      - "./conf:/etc/cas"
    env_file: .env
```

Au premier demarrage le container va creer : 

* /etc/cas/config/cas.properties avec les variables d'environnement renseignées dans .env.
* /etc/cas/config/log4j2.xml
* /etc/cas/theme : le theme (css, js, images)
* /etc/cas/templates/custom : les modeles des pages html du serveur
* /etc/cas/saml : pour la signature des requetes saml

Une fois ces fichiers générés vous pouvez les modifier à volonté. Ils seront exploités par le container mais ils ne seront plus générés. 
