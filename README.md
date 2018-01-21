# alpine-base-php7


Alpine base image for PHP 7 apps

---

# Startup process

The entrypoint is set to `/etc/entrypoint` which will:

* import & display build info by running `/etc/build-info`
* source `/etc/rc.local` that descendant images may use to include commands to be run at startup
* start s6-svscan to monitor the following processes:
    * `newrelic-daemon`: Acts as a proxy between the PHP agent and the New Relic servers
    * `nginx`: Serves content from `/app/public/` over HTTP at port 80
    * `php-fpm`: Listens on a UNIX socket and executes PHP code for NGINX

# Environment variables

This image expects the following environment variable to be set:

* `NEW_RELIC_LICENSE_KEY`: Sets the New Relic license key to use (defaults to disabled)
* `NEW_RELIC_APP_NAME`: Sets the name of the application that will be used in the New Relic UI (defaults to `alpine-base-php7`)

# How to use this image

Create a ```Dockerfile``` at the root of your app repo, substituting ```%%APP_NAME%%``` with your app's BitBucket repo name:

```
#
# ALL CHANGES TO THIS FILE MUST BE REVIEWED BY DEVOPS
#

FROM pengyue/alpine-php7:latest

# Add app
COPY php-app /app

# Set permissions for build
RUN mkdir -p /app/vendor/ && \
    chown -R build:build /app/vendor/ && \
    mkdir -p /app/bootstrap/cache/ && \
    chown -R build:build /app/bootstrap/cache/

# Run composer install as user 'build' and clean up the cache
USER build
RUN composer install --no-interaction --no-ansi --no-progress --prefer-dist && composer clear-cache --no-ansi --quiet
USER root

# Fix permissions
RUN chown -R root:root /app/vendor/ && \
    chmod -R go-w /app/vendor/ && \
    chown -R www:www /app/bootstrap/cache/ && \
    mkdir -p /app/storage/app/ && \
    chown -R www:www /app/storage/app/ && \
    mkdir -p /app/storage/framework/cache/ && \
    chown -R www:www /app/storage/framework/cache/

# Record build info
RUN /etc/build-info record %%APP_NAME%%
```

Create a ```Makefile``` at the root of your app repo:
```
#
# ALL CHANGES TO THIS FILE MUST BE REVIEWED BY DEVOPS
#

BASE = pengyue
NAME = %%APP_NAME%%

.PHONY: all build test shell run clean

all: build test

build:
	docker build --pull --force-rm -t ${BASE}/${NAME}:local .

test:
	@echo "WARNING: 'test' target not implemented!"

shell:
	docker run -P --rm -it --name ${NAME} ${BASE}/${NAME}:local /bin/sh

run:
	docker run -P --rm --name ${NAME} ${BASE}/${NAME}:local

clean:
	docker rmi ${BASE}/${NAME}:local
```

Provided you have Docker installed, the following make commands should be available:

* ```make build```: Builds a docker container image
* ```make shell```: Starts the last built docker container image and drops into a shell
* ```make run```: Runs the last built docker container image as it'd run in production
* ```make clean```: Removes the last built docker container image

Please contact DevOps if you require any assistance or to setup an automated build on Quay.
