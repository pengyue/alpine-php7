FROM alpine:3.6

MAINTAINER Peng Yue <penyue@gmail.com>

# Used only to force cache invalidation
ARG CACHE_BUSTER=2017-08-18-A

# Setup a simple and informative shell prompt
ENV PS1='\u@\h.${POD_NAMESPACE}:/\W \$ '

# Add a user 'build' to run the build and a user 'www' to run the app
RUN addgroup -g 9998 -S build && adduser -u 9998 -G build -S build && \
 addgroup -g 9999 -S www && adduser -u 9999 -G www -S www -H

# Install required packages
RUN apk upgrade --no-cache && \
 apk add --no-cache s6 bind-tools libcap ca-certificates openssl openssh bash git socat strace jq nano curl rsync mysql-client \
 nginx \
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
 rm -rf /etc/php7/conf.d/xdebug.ini && \
 ln -s /usr/sbin/php-fpm7 /usr/sbin/php-fpm

# Install New Relic
RUN PHP_EXTENSION=`php -i | grep "PHP Extension => " | cut -f4 -d' '` && \
 NR_VERSION=`wget -qO - https://download.newrelic.com/php_agent/release/ | grep -- '-linux-musl.tar.gz' | awk -F 'release/' '{ print $2 }' | awk -F '-linux-musl.tar.gz' ' { print $1"-linux-musl" }'` && \
 wget -qO - https://download.newrelic.com/php_agent/release/$NR_VERSION.tar.gz | \
 tar zx $NR_VERSION/agent/x64/newrelic-$PHP_EXTENSION.so $NR_VERSION/daemon/newrelic-daemon.x64 && \
 mv /$NR_VERSION/agent/x64/newrelic-$PHP_EXTENSION.so /usr/lib/php7/modules/newrelic.so && chown root:root /usr/lib/php7/modules/newrelic.so && \
 mv /$NR_VERSION/daemon/newrelic-daemon.x64 /usr/bin/newrelic-daemon && chown root:root /usr/bin/newrelic-daemon && \
 rm -rf /$NR_VERSION

# Install composer
RUN wget -qO /usr/local/bin/composer https://getcomposer.org/download/1.4.2/composer.phar && chmod +x /usr/local/bin/composer

# Install security checker
RUN wget -qO /usr/local/bin/security-checker http://get.sensiolabs.org/security-checker.phar && chmod +x /usr/local/bin/security-checker

# Add config files and fix permissions
COPY etc /etc/
COPY ssh /home/build/.ssh/
RUN chown -R build:build /home/build/ && chmod 0600 /home/build/.ssh/id_rsa && chmod go-w /etc/shells && rm -rf /var/www && chown -R root:root /var/lib/nginx /usr/sbin/nginx

# Install composer parallel install plugin
USER build
RUN composer global require "hirak/prestissimo:^0.3" --no-interaction --no-ansi --quiet --no-progress --prefer-dist && composer clear-cache --no-ansi --quiet && chmod -R go-w ~/.composer/vendor/
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