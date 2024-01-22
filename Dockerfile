ARG BASE_IMAGE="eclipse-temurin:11-jdk"
ARG PROD_IMAGE="tomcat:9-jdk11"
ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

FROM $BASE_IMAGE as overlay
ENV CAS_BRANCH_VERSION=6.6

RUN apt-get update && \
    apt-get install -y git

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
    apt-get install -y gettext-base
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*
RUN mkdir -p /data/logs
WORKDIR /data/logs
RUN mkdir -p /etc/cas/docs
COPY --from=overlay /tmp/tomcat /usr/local/tomcat/webapps
#copie du theme
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/css/cas.css /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/css/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/js/cas.js /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/js/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/favicon.ico /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/images/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/images/cas-logo.png /usr/local/tomcat/webapps/cas/WEB-INF/classes/static/themes/custom/images/mylogo.png

# sauvegarde du theme
RUN mkdir /data/theme 
RUN mkdir /data/theme/css 
RUN mkdir /data/theme/js 
RUN mkdir /data/theme/images 
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/css/cas.css /data/theme/css/
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/js/cas.js /data/theme/js
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/favicon.ico  /data/theme/images
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/static/images/cas-logo.png /data/theme/images

#some documentations 
COPY --from=overlay /tmp/cas-overlay/config-metadata.properties /etc/cas/docs
RUN mkdir /data/templates
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/templates/ /data/templates

#templates
COPY --from=overlay /tmp/cas-overlay/build/cas-resources/templates/ /usr/local/tomcat/webapps/cas/WEB-INF/classes/templates/custom 
COPY rootfs /

ENTRYPOINT "/entrypoint.sh"

