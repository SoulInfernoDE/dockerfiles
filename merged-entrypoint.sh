#!/bin/sh
./nextcloud-entrypoint.sh \
&& /usr/local/bin/./redis-entrypoint.sh
