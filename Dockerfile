FROM alpine:latest
FROM soulinferno/synonextcloudfpm:mariadb-11
COPY ./files/apk/* /tmp/
RUN apk add wget --no-cache \
    && wget https://github.com/SoulInfernoDE/dockerfiles/releases/download/alpine-11.0.2/mariadb-11.0.2-r0.apk /tmp/ \
    touch localinstall-empty.list && apk add --repositories-file=repo.list --allow-untrusted --no-network --no-cache /tmp/mariadb-*.apk \
    mkdir /docker-entrypoint-initdb.d && \
    mkdir /scripts/pre-exec.d && \
    mkdir /scripts/pre-init.d && \
    chmod -R 755 /scripts \
    /usr/sbin/mariadbd --unix-socket=ON
EXPOSE 3306

VOLUME ["/var/lib/mysql"]
