#!/bin/bash
echo "-----setup--------"
echo "directories creation"
mkdir -p /etc/cas/config 2>/dev/null
mkdir -p /etc/cas/themes 2>/dev/null
mkdir -p /etc/cas/saml 2>/dev/null
mkdir -p /etc/cas/services 2>/dev/null
if [ ! -f /etc/cas/config/cas.properties ] ; then
        echo "create cas.properties"
        cat /data/etc/cas.properties|envsubst >/etc/cas/config/cas.properties
fi
if [ ! -f /etc/cas/config/management.properties ] ; then
        echo "create management.properties"
        cat /data/etc/management.properties|envsubst >/etc/cas/config/management.properties
fi
if [ ! -f /etc/cas/services/casclient-1.json ] ; then
        echo "create casclient-1.json"
        cat /data/etc/casclient-1.json|envsubst >/etc/cas/services/cas-client-1.json
fi

if [ ! -f /etc/cas/config/log4j2.xml ]; then
     cp /data/etc/log4j2.xml /etc/cas/config/log4j2.xml
fi
if [ ! -f /etc/cas/config/admin-users.json ]; then
     cp /data/etc/admin-users.json /etc/cas/config
fi
if [ ! -f /etc/cas/thekeystore ] ; then
    echo "generate keystore"
    cd /etc/cas 
    CN=`echo -n $CAS_HOSTNAME|md5sum|cut -f1 -d " "`
    keytool -genkey -noprompt -keystore thekeystore -storepass changeit -keypass changeit -validity 3650 -keysize 2048 -keyalg RSA -dname "CN=$CN, OU=CERT, O=CAS, C=ORG"
fi
if [ -r /etc/cas/config/certificate.pem ]; then 
    keytool -noprompt -importcert -keystore /etc/ssl/certs/java/cacerts -storepass changeit -file /etc/cas/config/certificate.pem -alias "casclient"  
fi

if [ ! -d /etc/cas/templates/custom ] ; then
    mkdir -p /etc/cas/templates/custom 2>/dev/null
    cp -r  /usr/local/tomcat/webapps/cas/WEB-INF/classes/templates/custom/*  /etc/cas/templates/custom
else 
    echo "Update templates"
    cp -r  /etc/cas/templates/custom/* /usr/local/tomcat/webapps/cas/WEB-INF/classes/templates/custom/

fi 

if [ ! -d /etc/cas/themes/custom/css ] ; then
    echo "Creation themes"
    mkdir -p /etc/cas/themes/custom  2>/dev/null
    cp -r /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/* /etc/cas/themes
    cp /usr/local/tomcat/webapps/cas/WEB-INF/classes/*.properties /etc/cas/themes
    rm -rf /etc/cas/themes/git.properties
else
    echo "Update themes"
    cp -r /etc/cas/themes/* /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes
    cp /etc/cas/themes/*.properties /usr/local/tomcat/webapps/cas/WEB-INF/classes
fi
# server configuration 
if [ -z ${CAS_URI} ];then
  export CAS_URI=/cas
fi
cat /data/tomcat/server.xml|envsubst >/usr/local/tomcat/conf/server.xml


. /usr/local/tomcat/bin/catalina.sh run
