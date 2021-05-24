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
NBK_BASE_IMG_REPO?=jcrattzama/data_cube_notebooks
NBK_BASE_IMG_VER?=
export NBK_BASE_IMG?=${NBK_BASE_IMG_REPO}:odc${ODC_VER}${NBK_BASE_IMG_VER}
NBK_OUT_IMG_REPO?=jcrattzama/odc_training_notebooks
NBK_OUT_IMG_VER?=
export NBK_OUT_IMG?=${NBK_OUT_IMG_REPO}:odc${ODC_VER}${NBK_OUT_IMG_VER}
## End Notebooks ##

## Indexer ##
IDXR_BASE_IMG_REPO?=jcrattzama/odc_manual_indexer
IDXR_BASE_IMG_VER?=
export IDXR_BASE_IMG?=${IDXR_BASE_IMG_REPO}:odc${ODC_VER}${IDXR_BASE_IMG_VER}
IDXR_INIT_BASE_IMG_REPO?=jcrattzama/manual_indexer_init
IDXR_INIT_BASE_IMG_VER?=
export IDXR_INIT_BASE_IMG?=${IDXR_INIT_BASE_IMG_REPO}:odc${ODC_VER}${IDXR_INIT_BASE_IMG_VER}
## End Indexer ##

## Database ##
export DB_BASE_IMG?=postgres:10-alpine
export ODC_DB_HOSTNAME=odc_training_db
export ODC_DB_DATABASE=datacube
export ODC_DB_USER=dc_user
export ODC_DB_PASSWORD=localuser1234
export ODC_DB_PORT=5432
## End Database ##

COMMON_EXPRTS=export NBK_BASE_IMG=${NBK_BASE_IMG}; export NBK_OUT_IMG=${NBK_OUT_IMG}; \
			  export DB_BASE_IMG=${DB_BASE_IMG}; export DB_OUT_IMG=${DB_OUT_IMG}
eval ${COMMON_EXPRTS}

## Common ##
build:
	$(docker_compose) build

# Start the notebooks environment
up:
	$(docker_compose) up -d --build

# Start without rebuilding the Docker image
# (use when dependencies have not changed for faster starts).
up-no-build:
	$(docker_compose) up -d

# Stop the notebooks environment
down:
	$(docker_compose) stop

restart: down up

restart-no-build: down up-no-build

# List the running containers.
ps:
	$(docker_compose) ps

# Start an interactive shell to the notebooks container.
notebooks-ssh:
	$(docker_compose) exec notebooks bash

# Start an interactive shell to the indexer container.
indexer-ssh:
	$(docker_compose) exec indexer bash

## End Common ##

## Database ##

db-ssh:
	$(docker_compose) exec odc_training_db bash

# Create the persistent volume for the ODC database.
create-odc-db-volume:
	docker volume create odc-training-db-vol

# Delete the persistent volume for the ODC database.
delete-odc-db-volume:
	docker volume rm odc-training-db-vol

recreate-odc-db-volume: delete-odc-db-volume create-odc-db-volume

restore-db:
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

## End Database ##
