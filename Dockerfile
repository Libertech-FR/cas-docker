ARG BASE_IMAGE="eclipse-temurin:11-jdk"
ARG PROD_IMAGE="tomcat:9-jre11"
ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

FROM $BASE_IMAGE as overlay
ENV CAS_BRANCH_VERSION=6.6
ENV MGNT_BRANCH_VERSION=6.6.x

RUN apt-get update && \
    apt-get install -y git 

# MANAGEMENT 

#RUN git clone --branch $MGNT_BRANCH_VERSION  https://github.com/apereo/cas-management.git /tmp/cas-management

#WORKDIR /tmp/cas-management

#RUN ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS


RUN git clone --branch $CAS_BRANCH_VERSION --single-branch https://github.com/apereo/cas-overlay-template.git /tmp/cas-overlay

WORKDIR /tmp/cas-overlay

COPY src/ /tmp/cas-overlay/

RUN ./gradlew createTheme -Ptheme=custom

RUN ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS

RUN ls -la /tmp/cas-overlay/build/libs/cas.war

RUN ./gradlew unzipWAR

RUN ./gradlew unzip 

RUN ./gradlew exportConfigMetadata

RUN mkdir /tmp/tomcat 

RUN ls /tmp/cas-overlay/build/app
RUN mv /tmp/cas-overlay/build/app /tmp/tomcat/cas


RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*

FROM $PROD_IMAGE as cas

RUN apt-get update && \
    apt-get install -y gettext-base unzip
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*
RUN mkdir -p /data/logs
WORKDIR /data/logs
RUN mkdir -p /etc/cas/docs
COPY --from=overlay /tmp/tomcat /usr/local/tomcat/webapps
#copie du theme
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/css/cas.css /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/css/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/js/cas.js /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/js/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/js/material.js /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/js/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/favicon.ico /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/images/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/images/cas-logo.png /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/images/mylogo.png

# Install management 
#COPY --from=overlay /tmp/cas-management/webapp/cas-mgmt-webapp/build/libs/cas-mgmt-webapp-6.6.5-SNAPSHOT.war /usr/local/tomcat/webapps
#RUN mkdir /usr/local/tomcat/webapps/cas-management
#RUN unzip /usr/local/tomcat/webapps/cas-mgmt-webapp-6.6.5-SNAPSHOT.war -d /usr/local/tomcat/webapps/cas-management
#RUN rm -rf /usr/local/tomcat/webapps/cas-mgmt-webapp-6.6.5-SNAPSHOT.war

# sauvegarde du theme
RUN mkdir /data/themes/ 
RUN mkdir /data/themes/custom
RUN mkdir /data/themes/custom/css 
RUN mkdir /data/themes/custom/js 
RUN mkdir /data/themes/custom/images 
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/css/cas.css /data/themes/custom/css/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/js/cas.js /data/themes/custom/js
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/favicon.ico  /data/themes/custom/images
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/images/cas-logo.png /data/themes/custom/images

#some documentations 
COPY --from=overlay /tmp/cas-overlay/config-metadata.properties /etc/cas/docs

RUN mkdir /data/templates
# repertoire pour les certificats 
RUN mkdir /etc/cert

COPY --from=overlay /tmp/cas-overlay/build/cas-resources/templates/ /data/templates

#templates
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/templates/ /usr/local/tomcat/webapps/cas/WEB-INF/classes/templates/custom 
COPY rootfs /
#catalina.properties skiplist 
RUN /usr/bin/scan.sh /usr/local/tomcat >>/usr/local/tomcat/conf/catalina.properties 
RUN cp /usr/local/tomcat/webapps/cas/WEB-INF/classes/custom.properties /data/themes
EXPOSE 80
EXPOSE 443

ENTRYPOINT "/entrypoint.sh"

