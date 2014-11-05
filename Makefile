.PHONY: build run run-dovecot run-postgres build-postgres build-dovecot \
		stop-postgres psql-postgres

HOST_DIR = /srv/docker-mail
BUILD = production

DC_IMG := dovecot:latest
DC_NAME := dockermail-dovecot-$(BUILD)
DC_VOLUME := $(HOST_DIR)/dovecot/vmail:/srv/vmail

PG_IMG = postgres:9.3
PG_NAME := dockermail-postgres-$(BUILD)
PG_VOLUME := $(HOST_DIR)/postgresql/data:/var/lib/postgresql/data

build: build-postgres build-dovecot

postgres-init-db:
	@echo "CREATE ROLE dockermail LOGIN; CREATE DATABASE dockermail WITH OWNER dockermail TEMPLATE template0 ENCODING 'UTF8';" | \
		docker run \
			--rm \
			--interactive \
			--link $(PG_NAME):postgres \
			--entrypoint=\"\" \
			-v $(PG_VOLUME) \
			$(PG_IMG) \
			bash -c 'exec psql -h postgres -U postgres'

	@cat dovecot/initdb.pgsql | \
		docker run \
			--rm \
			--interactive \
			--link $(PG_NAME):postgres \
			--entrypoint=\"\" \
			-v $(PG_VOLUME) \
			$(PG_IMG) \
			bash -c 'exec psql -h postgres -U dockermail -d dockermail'

run-postgres: 
	@if [[ $$(docker ps -a | grep "$(PG_NAME)" | awk '{print $$(NF)}') == "$(PG_NAME)" ]]; then \
		docker start $(PG_NAME); \
	else \
		docker run -d -v $(PG_VOLUME) --name $(PG_NAME) $(PG_IMG); \
	fi 

psql-postgres:
	@docker run \
		--rm \
		--interactive \
		--tty \
		--link $(PG_NAME):postgres \
		-v $(PG_VOLUME)	\
		$(PG_IMG) \
		bash -c 'exec psql -h postgres -U postgres' 

stop-postgres:
	@docker stop $(PG_NAME)

build-dovecot:
	@cd dovecot; docker build -t $(DC_IMG) .

run-dovecot:
	@if [[ $$(docker ps -a | grep "$(DC_NAME)" | awk '{print $$(NF)}') == "$(DC_NAME)" ]]; then \
		docker start $(DC_NAME); \
	else \
		docker run -d -p 25:25 -p 587:587 -p 993:993 --link $(PG_NAME):postgres \
			   -v $(DC_VOLUME) --name $(DC_NAME) $(DC_IMG); \
	fi

