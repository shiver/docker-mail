.PHONY: build run stop clean \
		run-dovecot stop-dovecot build-dovecot \
		run-postgres stop-postgres build-postgres psql-postgres \
		run-roundcube stop-roundcube build-roundcube

SHELL := /bin/bash
HOST_DIR = /srv/docker-mail
BUILD = production

DC_IMG := dovecot:latest
DC_NAME := dockermail-dovecot-$(BUILD)
DC_VOLUME := $(HOST_DIR)/dovecot/vmail:/var/mail

PG_IMG = postgres:9.3
PG_NAME := dockermail-postgres-$(BUILD)
PG_VOLUME := $(HOST_DIR)/postgresql/data:/var/lib/postgresql/data

RC_IMG = roundcube:1.0.3
RC_NAME := dockermail-roundcube-$(BUILD)
RC_VOLUME := $(HOST_DIR)/roundcube:/var/lib/roundcube

build: build-postgres build-dovecot build-roundcube

run: run-postgres run-dovecot run-roundcube

stop: stop-roundcube stop-dovecot stop-postgres

clean: clean-roundcube clean-dovecot clean-postgres

clean-roundcube:
	@docker rm $(RC_NAME)

clean-dovecot:
	@docker rm $(DC_NAME)

clean-postgres:
	@docker rm $(PG_NAME)

add-domain:
	@echo "INSERT INTO virtual_domains(name) VALUES('$(DOMAIN)');" | \
		docker run \
			--rm \
			--interactive \
			--link $(PG_NAME):postgres \
			--entrypoint=\"\" \
			-v $(PG_VOLUME) \
			$(PG_IMG) \
			bash -c 'exec psql -h postgres -U dockermail -d dockermail'

add-user:
	@echo "INSERT INTO virtual_users(domain_id, password, email) SELECT id, '$(PASSWD)', '$(EMAIL)' FROM virtual_domains WHERE name='$(DOMAIN)';" | \
		docker run \
			--rm \
			--interactive \
			--link $(PG_NAME):postgres \
			--entrypoint=\"\" \
			-v $(PG_VOLUME) \
			$(PG_IMG) \
			bash -c 'exec psql -h postgres -U dockermail -d dockermail'

add-alias:
	@echo "INSERT INTO virtual_aliases(domain_id, source, destination) SELECT id, '$(ALIAS)', '$(EMAIL)' FROM virtual_domains WHERE name='$(DOMAIN)';" | \
		docker run \
			--rm \
			--interactive \
			--link $(PG_NAME):postgres \
			--entrypoint=\"\" \
			-v $(PG_VOLUME) \
			$(PG_IMG) \
			bash -c 'exec psql -h postgres -U dockermail -d dockermail'

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

stop-dovecot:
	@docker stop $(DC_NAME)

run-dovecot:
	@if [[ $$(docker ps -a | grep "$(DC_NAME)" | awk '{print $$(NF)}') == "$(DC_NAME)" ]]; then \
		docker start $(DC_NAME); \
	else \
		docker run -d -p 25:25 -p 587:587 -p 993:993 --link $(PG_NAME):postgres \
				   -v $(DC_VOLUME) \
			   	   --name $(DC_NAME) $(DC_IMG); \
	fi

build-roundcube: 
	@cd roundcube; docker build -t $(RC_IMG) .

run-roundcube:
	@if [[ $$(docker ps -a | grep "$(RC_NAME)" | awk '{print $$(NF)}') == "$(RC_NAME)" ]]; then \
		docker start $(RC_NAME); \
	else \
		docker run -d -p 80:80 -p 443:443 --link $(PG_NAME):postgres \
				   --link $(DC_NAME):dovecot \
				   -v $(RC_VOLUME) --name $(RC_NAME) $(RC_IMG); \
	fi

stop-roundcube:
	@docker stop $(RC_NAME)

