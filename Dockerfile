FROM nextcloud:fpm-alpine

# Nextcloud env
ENV PHP_MEMORY_LIMIT 513M
ENV PHP_UPLOAD_LIMIT 20G
ENV NEXTCLOUD_VERSION 27.0.1


# REDIS env
ENV REDIS_VERSION 7.0.12
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-7.0.12.tar.gz
ENV REDIS_DOWNLOAD_SHA 9dd83d5b278bb2bf0e39bfeb75c3e8170024edbaf11ba13b7037b2945cf48ab7

# volumes for Nextcloud
VOLUME /var/www/html
# volumes for redis
VOLUME /data
# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
# FROM php:8.2-fpm-alpine3.18
# One Alpine base image layer should be enough and choosing the base of the nextcloud one seems to be reasonable for all others
# entrypoint.sh and cron.sh dependencies

RUN set -eux; \
    \
    apk add --no-cache \
        imagemagick \
        rsync \
# grab su-exec for easy step-down from root
	    'su-exec>=0.2' \
# add tzdata for https://github.com/docker-library/redis/issues/138
	    tzdata \

    ; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        autoconf \
        freetype-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng-dev \
        libwebp-dev \
        libxml2-dev \
        libzip-dev \
        openldap-dev \
        pcre-dev \
        postgresql-dev \
	    coreutils \
	    dpkg-dev dpkg \
	    gcc \
	    linux-headers \
	    make \
	    musl-dev \
	    openssl-dev \
 	    wget \
# install real "wget" to avoid:
#   + wget -O redis.tar.gz https://download.redis.io/releases/redis-6.0.6.tar.gz
#   Connecting to download.redis.io (45.60.121.1:80)
#   wget: bad header line:     XxhODalH: btu; path=/; Max-Age=900
    ; \
    \
#    rm /var/spool/cron/crontabs/root; \
    echo '*/5 * * * * php -f /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data \
    ; \
    \
# removed run layers to slim down image size

    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
       gmp \
        intl \
        ldap \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        sysvsem \
        zip \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
#    pecl install APCu-5.1.22; \
#    pecl install imagick-3.7.0; \
#    pecl install memcached-3.2.0; \
#    pecl install redis-5.3.7; \
    \
    docker-php-ext-enable \
        apcu \
        imagick \
        memcached \
        redis \
    ; \
    mkdir /tmp/pear; \
    rm -r /tmp/pear; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .nextcloud-phpext-rundeps $runDeps \

# install the PHP extensions we need
# see https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
# set recommended PHP.ini settings
# see https://docs.nextcloud.com/server/latest/admin_manual/installation/server_tuning.html#enable-php-opcache
    ; \
    \
      { \
        echo 'opcache.enable=1'; \
        echo 'opcache.interned_strings_buffer=32'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.jit=1255'; \
        echo 'opcache.jit_buffer_size=128M'; \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    \
    echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"; \
    \
    { \
        echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
        echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
        echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > "${PHP_INI_DIR}/conf.d/nextcloud.ini" \
    ; \
    \
#    mkdir /var/www/data; \
    mkdir -p /docker-entrypoint-hooks.d/pre-installation \
             /docker-entrypoint-hooks.d/post-installation \
             /docker-entrypoint-hooks.d/pre-upgrade \
             /docker-entrypoint-hooks.d/post-upgrade \
             /docker-entrypoint-hooks.d/before-starting; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www \
    ; \
    \
    apk add --no-cache --virtual .fetch-deps \
        bzip2 \
        gnupg \
    ; \
    \
    curl -fsSL -o nextcloud.tar.bz2 "https://download.nextcloud.com/server/releases/latest-27.tar.bz2"; \
    curl -fsSL -o nextcloud.tar.bz2.asc "https://download.nextcloud.com/server/releases/latest-27.tar.bz2.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
# gpg key from https://nextcloud.com/nextcloud.asc
    gpg --batch --keyserver keyserver.ubuntu.com  --recv-keys 28806A878AE423A28372792ED75899B9A724937A; \
    gpg --batch --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    mkdir -p /usr/src/; \    
    tar -xjf nextcloud.tar.bz2 -C /usr/src/; \
    gpgconf --kill all; \
    rm nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    rm -rf "$GNUPGHOME" /usr/src/nextcloud/updater; \
    mkdir -p /usr/src/nextcloud/data; \
    mkdir -p /usr/src/nextcloud/custom_apps; \
#    mkdir /upgrade.exclude; \
    chmod +x /usr/src/nextcloud/occ

COPY /entrypoint.sh entrypoint-nextcloud.sh
rm /entrypoint.sh
COPY *.sh upgrade.exclude /
COPY config/* /usr/src/nextcloud/config/

ENTRYPOINT ["/entrypoint-nextcloud.sh"]
CMD ["php-fpm"]


# FROM mariadb:11.0.2


# FROM redis:alpine but using nextcloud alpine base image
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# RUN addgroup -S -g 1000 redis \
#    adduser -S -G redis -u 999 redis
# alpine already has a gid 999, so we'll use the next id
RUN	wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL"; \
	echo "$REDIS_DOWNLOAD_SHA *redis.tar.gz" | sha256sum -c -; \
	mkdir -p /usr/src/redis; \
	tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1; \
	rm redis.tar.gz; \
	\
# disable Redis protected mode [1] as it is unnecessary in context of Docker
# (ports are not automatically exposed when running inside Docker, but rather explicitly by specifying -p / -P)
# [1]: https://github.com/redis/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' /usr/src/redis/src/config.c; \
	sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' /usr/src/redis/src/config.c; \
	grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' /usr/src/redis/src/config.c; \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
	\
# https://github.com/jemalloc/jemalloc/issues/467 -- we need to patch the "./configure" for the bundled jemalloc to match how Debian compiles, for compatibility
# (also, we do cross-builds, so we need to embed the appropriate "--build=xxx" values to that "./configure" invocation)
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	extraJemallocConfigureFlags="--build=$gnuArch"; \
# https://salsa.debian.org/debian/jemalloc/-/blob/c0a88c37a551be7d12e4863435365c9a6a51525f/debian/rules#L8-23
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64 | i386 | x32) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=12" ;; \
		*) extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-page=16" ;; \
	esac; \
	extraJemallocConfigureFlags="$extraJemallocConfigureFlags --with-lg-hugepage=21"; \
	grep -F 'cd jemalloc && ./configure ' /usr/src/redis/deps/Makefile; \
	sed -ri 's!cd jemalloc && ./configure !&'"$extraJemallocConfigureFlags"' !' /usr/src/redis/deps/Makefile; \
	grep -F "cd jemalloc && ./configure $extraJemallocConfigureFlags " /usr/src/redis/deps/Makefile; \
	\
	export BUILD_TLS=yes; \
	make -C /usr/src/redis -j "$(nproc)" all; \
	make -C /usr/src/redis install; \
	\
# TODO https://github.com/redis/redis/pull/3494 (deduplicate "redis-server" copies)
	serverMd5="$(md5sum /usr/local/bin/redis-server | cut -d' ' -f1)"; export serverMd5; \
	find /usr/local/bin/redis* -maxdepth 0 \
		-type f -not -name redis-server \
		-exec sh -eux -c ' \
			md5="$(md5sum "$1" | cut -d" " -f1)"; \
			test "$md5" = "$serverMd5"; \
		' -- '{}' ';' \
		-exec ln -svfT 'redis-server' '{}' ';' \
	; \
	\
	rm -r /usr/src/redis; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .redis-rundeps $runDeps; \
	apk del --no-network .build-deps; \
	apk del --no-network .fetch-deps; \
        ; \
	\
	redis-cli --version; \
	redis-server --version

# RUN mkdir /data \
RUN chown redis:redis /data
WORKDIR /data

# COPY docker-entrypoint.sh /usr/local/bin/
# ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD ["redis-server"]
# FROM nginx:latest
