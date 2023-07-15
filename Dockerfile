FROM alpine:latest
FROM soulinferno/synonextcloudfpm:mariadb-11
COPY ./apk/* /tmp/
RUN touch repo.list && apk add --repositories-file=repo.list --allow-untrusted --no-network --no-cache /tmp/mariadb-*.apk
RUN mkdir /docker-entrypoint-initdb.d && \
    mkdir /scripts/pre-exec.d && \
    mkdir /scripts/pre-init.d && \
    chmod -R 755 /scripts
RUN /usr/sbin/mariadbd --unix-socket=ON
EXPOSE 3306

VOLUME ["/var/lib/mysql"]
