FROM composer:latest AS composer
FROM alpine:3.9

LABEL Maintainer="Peng Yue <penyue@gmail.com>" \
      Description="Lightweight container with Nginx 1.14 & PHP-FPM 7.2 based on Alpine Linux."

# Used only to force cache invalidation
ARG CACHE_BUSTER=2019-12-01-A

# Setup a simple and informative shell prompt
ENV PS1='\u@\h.${POD_NAMESPACE}:/\W \$ '

# Add a user 'build' to run the build and a user 'www' to run the app
RUN addgroup -g 9998 -S build && adduser -u 9998 -G build -S build && \
 addgroup -g 9999 -S www && adduser -u 9999 -G www -S www -H

# Install composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN echo "https://dl.bintray.com/php-alpine/v3.9/php-7.3" >> /etc/apk/repositories

# Install required packages
RUN apk update --no-cache && \
 apk add --no-cache curl ca-certificates openrc s6 bind-tools libcap openssl openssh bash git socat strace jq vim rsync mysql-client nginx \
 --update php7 \
 php7-bcmath \
 php7-bz2 \
 php7-calendar \
 php7-ctype \
 php7-curl \
 php7-dom \
 php7-exif \
 php7-fileinfo \
 php7-fpm \
 php7-ftp \
 php7-gd \
 php7-gettext \
 php7-gmp \
 php7-iconv \
 php7-json \
 php7-mbstring \
 php7-mcrypt \
 php7-opcache \
 php7-openssl \
 php7-pcntl \
 php7-pdo_mysql \
 php7-pdo_sqlite \
 php7-phar \
 php7-posix \
 php7-session \
 php7-simplexml \
 php7-soap \
 php7-sockets \
 php7-sqlite3 \
 php7-tokenizer \
 php7-wddx \
 php7-xdebug \
 php7-xml \
 php7-xmlreader \
 php7-xmlrpc \
 php7-xmlwriter \
 php7-xsl \
 php7-zip \
 php7-zlib && \
# apk add --update php-common@php && \
 ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm && \
 rm -rf /etc/php7/conf.d/xdebug.ini && \
 rm -rf /var/cache/apk/*

# Install New Relic
RUN PHP_EXTENSION=`php -i | grep "PHP Extension => " | cut -f4 -d' '` && \
 NR_VERSION=`wget -qO - https://download.newrelic.com/php_agent/release/ | grep -- '-linux-musl.tar.gz' | awk -F 'release/' '{ print $2 }' | awk -F '-linux-musl.tar.gz' ' { print $1"-linux-musl" }'` && \
 wget -qO - https://download.newrelic.com/php_agent/release/$NR_VERSION.tar.gz | \
 tar zx $NR_VERSION/agent/x64/newrelic-$PHP_EXTENSION.so $NR_VERSION/daemon/newrelic-daemon.x64 && \
 mv /$NR_VERSION/agent/x64/newrelic-$PHP_EXTENSION.so /usr/lib/php7/modules/newrelic.so && chown root:root /usr/lib/php7/modules/newrelic.so && \
 mv /$NR_VERSION/daemon/newrelic-daemon.x64 /usr/bin/newrelic-daemon && chown root:root /usr/bin/newrelic-daemon && \
 rm -rf /$NR_VERSION

# Install security checker
RUN wget -qO /usr/local/bin/security-checker http://get.sensiolabs.org/security-checker.phar && chmod +x /usr/local/bin/security-checker

RUN rc-update add s6 default

# Add config files and fix permissions
COPY etc /etc/
RUN chown -R build:build /home/build/ && \
    chmod go-w /etc/shells && \
    rm -rf /var/www && \
    chown -R root:root /var/lib/nginx /usr/sbin/nginx

# Install composer parallel install plugin
USER build
RUN composer global require "hirak/prestissimo:^0.3" --no-interaction --no-ansi --quiet --no-progress --prefer-dist && \
    composer clear-cache --no-ansi --quiet && \
    chmod -R go-w ~/.composer/vendor/
USER root

# Add the sample app
WORKDIR /app
COPY app /app/

# Expose the http port, define the entrypoint and record the build info
EXPOSE 80
ENTRYPOINT ["/etc/entrypoint"]
RUN /etc/build-info record alpine-base-php7

# Set a trigger to purge the sample app on descendants
ONBUILD RUN rm -rf /app/public/*
