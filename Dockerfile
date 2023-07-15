FROM alpine:latest

 LABEL architecture="amd64/x86_64" \
    mariadb-version="11.0.2" \
    alpine-version="latest" \
    build="15-Jul-2023" \
    org.opencontainers.image.description="MariaDB Docker image running on Alpine Linux"

RUN apk add pwgen wget --no-cache \
    wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-common-11.0.2-r0.apk \
    wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-server-utils-11.0.2-r0.apk \
    wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-client-11.0.2-r0.apk \
    wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-11.0.2-r0.apk /tmp/ \
    wget https://raw.githubusercontent.com/SoulInfernoDE/dockerfiles/mariadb-11/files/run.sh \
    touch localinstall-empty.list \
    apk add --repositories-file=localinstall-empty.list --allow-untrusted --no-network --no-cache /tmp/mariadb-*.apk \
    rm /tmp/mariadb-*.apk \
    mkdir /docker-entrypoint-initdb.d && \
    mkdir /scripts/pre-exec.d && \
    mkdir /scripts/pre-init.d && \
    chmod -R 755 /scripts \
    
EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/run.sh"]
