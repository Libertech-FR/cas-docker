ARG BASE_IMAGE="azul/zulu-openjdk:21"
ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

FROM $BASE_IMAGE as overlay

RUN cd /tmp && \
    apt-get update && \
    apt-get install -y git && \
    git clone -b master --single-branch https://github.com/apereo/cas-overlay-template.git cas-overlay

WORKDIR /tmp/cas-overlay

COPY src/ /tmp/cas-overlay/src/

RUN ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS

FROM $BASE_IMAGE as cas

RUN mkdir -p /etc/cas && \
    cd /etc/cas && \
    keytool -genkey -noprompt -keystore thekeystore -storepass changeit -keypass changeit -validity 3650 \
      -keysize 2048 -keyalg RSA -dname "CN=localhost, OU=MyOU, O=MyOrg, L=Somewhere, S=VA, C=US"
RUN if [ -r /etc/cas/config/certificate.pem ]; then \
    keytool -noprompt -importcert -keystore /etc/ssl/certs/java/cacerts -storepass changeit \
      -file /etc/cas/config/certificate.pem -alias "casclient"; \
    fi

WORKDIR /data

COPY --from=overlay /tmp/cas-overlay/build/libs/cas.war .
COPY rootfs /

EXPOSE 8080 8443

ENTRYPOINT ["java", "-server", "-noverify", "-Xmx2048M", "-jar", "cas.war"]