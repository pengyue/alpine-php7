BASE = pengyue
NAME = alpine-php7

.PHONY: all build test shell run clean

all: build test

build:
	docker build --pull --force-rm -t ${BASE}/${NAME}:local .

test:
	@echo "WARNING: 'test' target not implemented!"

shell:
	docker run -P --rm -it --name ${NAME} ${BASE}/${NAME}:local /bin/sh

run:
	docker run -P --rm --name ${NAME} -d ${BASE}/${NAME}:local

clean:
	docker rmi ${BASE}/${NAME}:local
