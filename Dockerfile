FROM alpine:latest
FROM soulinferno/synonextcloudfpm:mariadb-11
LABEL architecture="amd64/x86_64" \
    mariadb-version="11.0.2" \
    alpine-version="latest" \
    build="15-Jul-2023" \
COPY files/apk/* /tmp/ \
     files/run.sh /scripts/run.sh
RUN apk add pwgen wget --no-cache \
    && wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-11.0.2-r0.apk /tmp/ \
    touch localinstall-empty.list && apk add --repositories-file=localinstall-empty.list --allow-untrusted --no-network --no-cache /tmp/mariadb-*.apk \
    mkdir /docker-entrypoint-initdb.d && \
    mkdir /scripts/pre-exec.d && \
    mkdir /scripts/pre-init.d && \
    chmod -R 755 /scripts \
    
EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/scripts/run.sh"]
