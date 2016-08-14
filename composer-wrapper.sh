#!/bin/sh

mkdir -p /etc/php/conf.disabled.d
mv /etc/php/conf.d/xdebug.ini /etc/php/conf.disabled.d/
php /usr/local/lib/phpqa/composer.phar $@
STATUS=$?
mv /etc/php/conf.disabled.d/xdebug.ini /etc/php/conf.d/
return $STATUS 
