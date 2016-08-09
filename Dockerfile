FROM alpine:edge

MAINTAINER Matthijs van den Bos <matthijs@vandenbos.org>

COPY setuser.sh /usr/local/bin
COPY setuid-runner.sh /usr/local/bin

WORKDIR /tmp

ENV USER_DIR="/app" \
    COMPOSER_HOME="/tmp/.composer" \
    COMPOSER_BIN_DIR="/usr/local/bin" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    TIMEZONE=Europe/Amsterdam \
    PHP_MEMORY_LIMIT=512M

COPY install-composer.sh /tmp

# This is a wrapper script that disables the php.ini, so 
# that xdebug will be unloaded. This way composer won't be slowed by it.
COPY composer-wrapper.sh /usr/local/bin/composer

RUN	echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
	apk upgrade && \
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone && \
	apk add --update \
	    su-exec \ 
	    wget \
	    php5 \
		php5-mcrypt \
		php5-soap \
		php5-openssl \
		php5-json \
		php5-dom \
		php5-zip \
		php5-bcmath \
		php5-gd \
		php5-gettext \
		php5-xmlreader \
		php5-xmlrpc \
		php5-bz2 \
		php5-iconv \
		php5-curl \
		php5-xdebug \
		php5-phar \
		php5-sqlite3 \
		php5-ctype && \

    # Make php5 the default php
    ln -s /etc/php5 /etc/php && \
    ln -s /usr/lib/php5 /usr/lib/php && \

    # Set environments
	sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php/php.ini && \
	sed -i "s|;*memory_limit =.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php/php.ini && \

    # Cleaning up
	apk del tzdata && \
	rm -rf /var/cache/apk/*

# Run composer and phpunit installation.
RUN /tmp/install-composer.sh && \
    composer selfupdate && \
    composer require --prefer-stable --prefer-dist \ 
        "phpunit/phpunit:^4" \
        "squizlabs/php_codesniffer:3.0.x-dev" \
        "phpmd/phpmd:^2" \
        "friendsofphp/php-cs-fixer:^1" \
        "sebastian/phpcpd:^2" && \

    # make things writable for host user, so we can configure php, even when
    # running through our setuid-runner.sh script
    chmod -R a+rwX /etc/php && \
    chmod -R a+rwX /tmp

VOLUME "/app"

# Stolen from http://stackoverflow.com/a/27925525/844313
ENTRYPOINT ["/usr/local/bin/setuid-runner.sh"]
