ARG BASE_IMAGE="eclipse-temurin:11-jdk"
ARG EXT_BUILD_COMMANDS=""
ARG EXT_BUILD_OPTIONS=""

FROM $BASE_IMAGE as overlay
ENV CAS_BRANCH_VERSION=6.6

RUN apt-get update && \
    apt-get install -y git

RUN git clone --branch $CAS_BRANCH_VERSION --single-branch https://github.com/apereo/cas-overlay-template.git /tmp/cas-overlay

WORKDIR /tmp/cas-overlay

COPY src/ /tmp/cas-overlay/

RUN ./gradlew clean build $EXT_BUILD_COMMANDS --parallel --no-daemon $EXT_BUILD_OPTIONS

RUN ls -la /tmp/cas-overlay/build/libs/cas.war

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/*

FROM $BASE_IMAGE as cas

RUN mkdir -p /etc/cas && \
    cd /etc/cas && \
    keytool -genkey -noprompt -keystore thekeystore -storepass changeit -keypass changeit -validity 3650 \
      -keysize 2048 -keyalg RSA -dname "CN=localhost, OU=LT, O=Libertech, L=Somewhere, S=LT, C=FR"
RUN if [ -r /etc/cas/config/certificate.pem ]; then \
    keytool -noprompt -importcert -keystore /etc/ssl/certs/java/cacerts -storepass changeit \
      -file /etc/cas/config/certificate.pem -alias "casclient"; \
    fi

WORKDIR /data

COPY --from=overlay /tmp/cas-overlay/build/libs/cas.war .
COPY rootfs /

EXPOSE 8080 8443

ENTRYPOINT ["java", "-server", "-noverify", "-Xmx2048M", "-jar", "cas.war"]