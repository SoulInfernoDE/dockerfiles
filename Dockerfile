FROM alpine:latest

# define apk source urls
ARG RLSRC=https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-
#define actual version number
ARG RLVER=11.0.2
# define file ending
ARG FE=-r0.apk

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
    && wget -nv -P $TP \
    $RLSRC$RLVER/mariadb-common-$RLVER$FE \
    $RLSRC$RLVER/mariadb-server-utils-$RLVER$FE \
    $RLSRC$RLVER/mariadb-client-$RLVER$FE \
    $RLSRC$RLVER/mariadb-$RLVER$FE \
    
# using fixed version of run.sh - changed mysqld to mariadbd since newer versions dont have mysqld anymore or a symlink to it
    https://raw.githubusercontent.com/SoulInfernoDE/dockerfiles/mariadb-11/files/run.sh \
    && apk add --no-cache --allow-untrusted "$TP"mariadb-*.apk \
    && rm "$TP"mariadb-*.apk \
    && mkdir /docker-entrypoint-initdb.d/ \
    && mkdir /scripts/pre-exec.d/ \
    && mkdir /scripts/pre-init.d/ \
    && chmod -R 755 /scripts \
    
EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/run.sh"]
