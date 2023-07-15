FROM alpine:latest

# define apk source urls
ARG RLSRC=https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-
ARG RLVER=11.0.2

# define target path
ARG TP=/tmp/

 LABEL architecture="amd64/x86_64" \
    mariadb-version="11.0.2" \
    alpine-version="latest" \
    build="15-Jul-2023" \
    org.opencontainers.image.description="MariaDB Docker image running on Alpine Linux"

# install necessary dependencies, then download the files generated from source to $TP and install them locally
RUN apk add --no-cache \
    pwgen \
    wget \
    && wget -P $TP \
    https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-common-11.0.2-r0.apk \
    https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-server-utils-11.0.2-r0.apk \
    https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-client-11.0.2-r0.apk \
    https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-11.0.2-r0.apk \
    https://raw.githubusercontent.com/SoulInfernoDE/dockerfiles/mariadb-11/files/run.sh \
    && touch localinstall-empty.list \
    && apk add --no-cache --allow-untrusted "$TP"mariadb-*.apk \
    && rm "$TP"mariadb-*.apk \
    && mkdir -v /docker-entrypoint-initdb.d/{/scripts/pre-exec.d/,/scripts/pre-init.d/}
    && chmod -R 755 /scripts \
    
EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/run.sh"]
