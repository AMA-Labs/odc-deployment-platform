SHELL:=/bin/bash
docker_compose = docker-compose --project-directory build/docker -f build/docker/docker-compose.yml

# Make the environment variables of the environment available here.
# include build/docker/dev/.env
# include build/docker/odc_db_restore/.env
# DEV_EXPRTS = "$(cat build/docker/dev/.env)"
# ODC_DB_RESTORE_EXPRTS = "$(cat build/docker/odc_db_restore/.env)"
# DEV_EXPRTS = "export $$(cat build/docker/dev/.env)"
# ODC_DB_RESTORE_EXPRTS = "export $$(cat build/docker/odc_db_restore/.env)"
# DEV_EXPRTS = "export $$(cat build/docker/dev/.env)"
# ODC_DB_RESTORE_EXPRTS = "export $$(cat build/docker/odc_db_restore/.env)"
# DEV_EXPRTS = "export $$(cat build/docker/dev/.env | xargs)"
# ODC_DB_RESTORE_EXPRTS = "export $$(cat build/docker/odc_db_restore/.env | xargs)"
# DEV_EXPRTS = "source build/docker/dev/.env"
# ODC_DB_RESTORE_EXPRTS = "source build/docker/odc_db_restore/.env"

ODC_VER?=1.8.3

## Notebooks ##
NBK_BASE_IMG_REPO_DRONE_PAPER?=jcrattzama/odc_drone_paper_notebooks
NBK_BASE_IMG_VER_DRONE_PAPER?=
export NBK_BASE_IMG_DRONE_PAPER?=${NBK_BASE_IMG_REPO_DRONE_PAPER}:odc${ODC_VER}${NBK_BASE_IMG_VER_DRONE_PAPER}
# _drone_paper
# NBK_OUT_IMG_REPO?=jcrattzama/odc_training_notebooks
# NBK_OUT_IMG_VER?=
# export NBK_OUT_IMG?=${NBK_OUT_IMG_REPO}:odc${ODC_VER}${NBK_OUT_IMG_VER}
NBK_OUT_IMG_BASE?=jcrattzama/odc_platform_notebooks
NBK_OUT_IMG_VER_DRONE_PAPER?=
export NBK_OUT_IMG_DRONE_PAPER?=${NBK_OUT_IMG_BASE}:drone_paper${NBK_OUT_IMG_VER_DRONE_PAPER}
# ${NBK_BASE_IMG_DRONE_PAPER}_platform
## End Notebooks ##

## Indexer ##
# IDXR_BASE_IMG_REPO?=jcrattzama/odc_manual_indexer
# IDXR_BASE_IMG_VER?=
# export IDXR_BASE_IMG?=${IDXR_BASE_IMG_REPO}:odc${ODC_VER}${IDXR_BASE_IMG_VER}
IDXR_INIT_BASE_IMG_REPO?=jcrattzama/manual_indexer_init
IDXR_INIT_BASE_IMG_VER?=
export IDXR_INIT_BASE_IMG_DRONE_PAPER?=${IDXR_INIT_BASE_IMG_REPO}:odc${ODC_VER}_drone_paper${IDXR_INIT_BASE_IMG_VER}
## End Indexer ##

## Database ##
export DB_BASE_IMG?=postgres:10-alpine
export ODC_DB_HOSTNAME=odc_db
export ODC_DB_DATABASE=datacube
export ODC_DB_USER=dc_user
export ODC_DB_PASSWORD=localuser1234
export ODC_DB_PORT=5432
## End Database ##

COMMON_EXPRTS=export DB_BASE_IMG=${DB_BASE_IMG}; 

eval ${COMMON_EXPRTS}

DRONE_PAPER_ENV_EXPRTS= \
	export NBK_BASE_IMG=${NBK_BASE_IMG_DRONE_PAPER}; \
	export NBK_OUT_IMG=${NBK_OUT_IMG_DRONE_PAPER}; \
	export IDXR_INIT_BASE_IMG=${IDXR_INIT_BASE_IMG_DRONE_PAPER}

## Common ##

### Drone Paper Environment ##
drone-paper-config:
	${DRONE_PAPER_ENV_EXPRTS}; $(docker_compose) config

drone-paper-build:
	${DRONE_PAPER_ENV_EXPRTS}; $(docker_compose) build

# Start the notebooks environment
drone-paper-up:
	${DRONE_PAPER_ENV_EXPRTS}; $(docker_compose) up -d --build

# Start without rebuilding the Docker image
# (use when dependencies have not changed for faster starts).
drone-paper-up-no-build:
	${DRONE_PAPER_ENV_EXPRTS}; $(docker_compose) up -d

# Stop the notebooks environment
drone-paper-down:
	${DRONE_PAPER_ENV_EXPRTS}; $(docker_compose) down --remove-orphans

drone-paper-restart: drone-paper-down drone-paper-up

drone-paper-restart-no-build: drone-paper-down drone-paper-up-no-build

drone-paper-docker-commit:
	docker commit docker_notebooks_1 ${NBK_OUT_IMG_DRONE_PAPER}

drone-paper-restore-db: restore-db drone-paper-docker-commit
### End Drone Paper Environment ##

# List the running containers.
ps:
	$(docker_compose) ps
## End Common ##

## Notebooks ##
# Start an interactive shell to the notebooks container.
notebooks-ssh:
	$(docker_compose) exec notebooks bash
## End Notebooks ##

## Indexer ##
# Start an interactive shell to the indexer container.
indexer-ssh:
	$(docker_compose) exec indexer bash
## End Indexer ##

## Database ##
db-ssh:
	$(docker_compose) exec odc_db bash

# Create the persistent volume for the ODC database.
create-odc-db-volume:
	docker volume create odc-platform-db-vol

# Delete the persistent volume for the ODC database.
delete-odc-db-volume:
	docker volume rm odc-platform-db-vol

recreate-odc-db-volume: delete-odc-db-volume create-odc-db-volume

start-odc-db:
	docker start docker_odc_db_1

stop-odc-db:
	docker stop docker_odc_db_1

restart-odc-db: stop-odc-db start-odc-db

recreate-odc-db-and-vol: down dkr-sys-prune recreate-odc-db-volume up-no-build

restore-db:
#	Restore index database
	$(docker_compose) exec indexer conda run -n odc bash -c \
	  "gzip -dkf db_dump.gz"
	$(docker_compose) exec indexer conda run -n odc bash -c \
	  "datacube system init"
	$(docker_compose) exec indexer conda run -n odc bash -c \
	  'PGPASSWORD=${ODC_DB_PASSWORD} psql -h ${ODC_DB_HOSTNAME} \
         -U ${ODC_DB_USER} ${ODC_DB_DATABASE} -c "DROP SCHEMA IF EXISTS agdc CASCADE;"'
	$(docker_compose) exec indexer conda run -n odc bash -c \
	  "PGPASSWORD=${ODC_DB_PASSWORD} psql -h ${ODC_DB_HOSTNAME} \
         -U ${ODC_DB_USER} ${ODC_DB_DATABASE} < db_dump &> restore.txt"
	$(docker_compose) exec indexer conda run -n odc bash -c \
	  "rm db_dump.gz"
#	Copy compressed data from the indexer container to the 
#   notebooks container and decompress it.
	mkdir -p tmp
	docker cp docker_indexer_1:/Datacube/data.tar.gz tmp
	docker cp tmp/data.tar.gz docker_notebooks_1:/Datacube/data.tar.gz
	$(docker_compose) exec notebooks bash -c \
	  "mkdir /Datacube/data; \
	   tar -xzf /Datacube/data.tar.gz -C /Datacube/data"
	rm -rf tmp
## End Database ##

## Misc ##
dkr-sys-prune:
	yes | docker system prune
## End Misc ##
