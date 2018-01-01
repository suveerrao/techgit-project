#!/bin/bash

set -e

# TODO Support for postgress and sqlite

# Default to MySQL
: ${DATABASE:=mysql}

if [[ "$DATABASE" == "mysql" ]]; then
    echo 'MySQL was chosen as database backend.'
    # if we're linked to MySQL and thus have credentials already, let's use them
    # Default to root
    : ${REVIEWBOARD_DB_USER:=${DBSERVER_ENV_MYSQL_USER:-root}}
    if [ "$REVIEWBOARD_DB_USER" = 'root' ]; then
        : ${REVIEWBOARD_DB_PASSWORD:=$DBSERVER_ENV_MYSQL_ROOT_PASSWORD}
    fi
    : ${REVIEWBOARD_DB_PASSWORD:=$DBSERVER_ENV_MYSQL_PASSWORD}
    # Default to "reviewboard"
    : ${REVIEWBOARD_DB_NAME:=${DBSERVER_ENV_MYSQL_DATABASE:-reviewboard}}
elif [[ "$DATABASE" == "postgresql" ]]; then
    echo 'PostgreSQL was chosen as database backend.'
    echo >&2 'ERROR: PostgreSQL support not implemented yet in Docker image.'
    exit 2
elif [[ "$DATABASE" == "sqlite3" ]]; then
    echo 'SQLite3 was chosen as database backend.'
    echo >&2 'ERROR: SQLite3 support not implemented yet in Docker image.'
    exit 2
fi

if [ -z "$REVIEWBOARD_DB_PASSWORD" ]; then
    echo >&2 'error: missing required REVIEWBOARD_DB_PASSWORD environment variable'
    echo >&2 '  Did you forget to -e REVIEWBOARD_DB_PASSWORD=... ?'
    echo >&2
    echo >&2 '  (Also of interest might be REVIEWBOARD_DB_USER and REVIEWBOARD_DB_NAME.)'
    exit 1
fi

: "${REVIEWBOARD_DB_HOSTNAME:=dbserver}"
: "${DOMAIN:=""}" # By defaulting this empty we set ALLOWED_HOSTS to '*', thus avoiding "Bad request 400" when accessed form non "localhost"

: ${CACHE_TYPE:=memcached} # Default to memcache
: ${CACHE_INFO:=""}

if [ "$CACHE_TYPE" = "memcached" ]; then
    : ${MEMCACHE_SERVER_ADDR:=${MEMCACHE_PORT_11211_TCP_ADDR:-localhost}} # Default to internal memcache
    : ${MEMCACHE_SERVER_PORT:=${MEMCACHE_PORT_11211_TCP_PORT:-11211}}
    : ${CACHE_INFO:="$MEMCACHE_SERVER_ADDR:$MEMCACHE_SERVER_PORT"}
fi

if [[ ! -d /var/www/reviewboard ]]; then
    echo "Configuring ReviewBoard site..."
    rb-site install --noinput \
        --domain-name="$DOMAIN" \
        --site-root=/ --static-url=static/ --media-url=media/ \
        --db-type=$DATABASE \
        --db-name="$REVIEWBOARD_DB_NAME" \
        --db-host="$REVIEWBOARD_DB_HOSTNAME" \
        --db-user="$REVIEWBOARD_DB_USER" \
        --db-pass="$REVIEWBOARD_DB_PASSWORD" \
        --web-server-type=apache --python-loader=wsgi\
        --cache-type="$CACHE_TYPE" --cache-info="$CACHE_INFO" \
        --admin-user=admin --admin-password=admin --admin-email=admin@example.com \
        /var/www/reviewboard/
    chown -R www-data:www-data /var/www/reviewboard/htdocs/media/uploaded
    chown -R www-data:www-data /var/www/reviewboard/htdocs/media/ext
    chown -R www-data:www-data /var/www/reviewboard/htdocs/static/ext
    chown -R www-data:www-data /var/www/reviewboard/data
    echo "============================================================"
    echo "Configuration done!"
fi

# Apache gets grumpy about PID files pre-existing
rm -f /usr/local/apache2/logs/httpd.pid
exec httpd -DFOREGROUND
