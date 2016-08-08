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
	    php7 \
		php7-mcrypt \
		php7-soap \
		php7-openssl \
		php7-json \
		php7-dom \
		php7-zip \
		php7-bcmath \
		php7-gd \
		php7-gettext \
		php7-xmlreader \
		php7-xmlrpc \
		php7-bz2 \
		php7-iconv \
		php7-curl \
		php7-xdebug \
		php7-mbstring \
		php7-phar \
		php7-ctype && \
    
    # Make php7 the default php
    ln -s /etc/php7 /etc/php && \
    ln -s /usr/bin/php7 /usr/bin/php && \
    ln -s /usr/lib/php7 /usr/lib/php && \

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
        "phpunit/phpunit:^5" \
        "squizlabs/php_codesniffer:^2" \
        "phpmd/phpmd:^2" \
        "friendsofphp/php-cs-fixer:^1" \
        "sebastian/phpcpd:^2" && \

    # make things writable for host user, so we can configure php, even when
    # running through our setuid-runner.sh script
    chmod -R a+rwX /etc/php7 && \
    chmod -R a+rwX /tmp

VOLUME "/app"

# Stolen from http://stackoverflow.com/a/27925525/844313
ENTRYPOINT ["/usr/local/bin/setuid-runner.sh"]
