SHELL:=/bin/bash
# Set the project name to the path - making underscore the path separator.
PWD=$(pwd)
project_name=$(shell echo $${PWD//\//_})
docker_compose = docker-compose --project-directory build/docker -f build/docker/docker-compose.yml -p $(project_name)

ODC_VER?=1.8.3

## Notebooks ##

NBK_OUT_IMG_BASE?=jcrattzama/odc_platform_notebooks

### Drone Paper ###
NBK_BASE_IMG_REPO_DRONE_PAPER?=jcrattzama/odc_drone_paper_notebooks
NBK_BASE_IMG_VER_DRONE_PAPER?=
export NBK_BASE_IMG_DRONE_PAPER?=${NBK_BASE_IMG_REPO_DRONE_PAPER}:odc${ODC_VER}${NBK_BASE_IMG_VER_DRONE_PAPER}
NBK_OUT_IMG_VER_DRONE_PAPER?=
export NBK_OUT_IMG_DRONE_PAPER?=${NBK_OUT_IMG_BASE}:drone_paper${NBK_OUT_IMG_VER_DRONE_PAPER}
### End Drone Paper ###

### ODC Training ###
NBK_BASE_IMG_REPO_ODC_TRAINING?=jcrattzama/odc_training_notebooks
NBK_BASE_IMG_VER_ODC_TRAINING?=
export NBK_BASE_IMG_ODC_TRAINING?=${NBK_BASE_IMG_REPO_ODC_TRAINING}:odc${ODC_VER}${NBK_BASE_IMG_VER_ODC_TRAINING}
NBK_OUT_IMG_VER_ODC_TRAINING?=
export NBK_OUT_IMG_ODC_TRAINING?=${NBK_OUT_IMG_BASE}:odc_training${NBK_OUT_IMG_VER_ODC_TRAINING}
### End ODC Training ###

### Google Earth Engine ###
NBK_BASE_IMG_REPO_VA_CUBE?=jcrattzama/odc_va_cube_notebooks
NBK_BASE_IMG_VER_VA_CUBE?=
export NBK_BASE_IMG_VA_CUBE?=${NBK_BASE_IMG_REPO_VA_CUBE}:odc${ODC_VER}${NBK_BASE_IMG_VER_VA_CUBE}
NBK_OUT_IMG_VER_VA_CUBE?=
export NBK_OUT_IMG_VA_CUBE?=${NBK_OUT_IMG_BASE}:odc_va_cube${NBK_OUT_IMG_VER_VA_CUBE}
### End Google Earth Engine ###
## End Notebooks ##

## Indexer ##
# These images are created by the `odc_db_init` 
# repository (https://github.com/jcrattz/odc_db_init).
IDXR_INIT_BASE_IMG_REPO?=jcrattzama/manual_indexer_init
IDXR_INIT_BASE_IMG_VER?=
export IDXR_INIT_BASE_IMG_DRONE_PAPER?=${IDXR_INIT_BASE_IMG_REPO}:odc${ODC_VER}_drone_paper${IDXR_INIT_BASE_IMG_VER}
export IDXR_INIT_BASE_IMG_ODC_TRAINING?=${IDXR_INIT_BASE_IMG_REPO}:odc${ODC_VER}__cdc_training${IDXR_INIT_BASE_IMG_VER}
export IDXR_INIT_BASE_IMG_VA_CUBE?=${IDXR_INIT_BASE_IMG_REPO}:odc${ODC_VER}__va_cube${IDXR_INIT_BASE_IMG_VER}
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

ODC_TRAINING_ENV_EXPRTS= \
	export NBK_BASE_IMG=${NBK_BASE_IMG_ODC_TRAINING}; \
	export NBK_OUT_IMG=${NBK_OUT_IMG_ODC_TRAINING}; \
	export IDXR_INIT_BASE_IMG=${IDXR_INIT_BASE_IMG_ODC_TRAINING}

VA_CUBE_ENV_EXPRTS= \
	export NBK_BASE_IMG=${NBK_BASE_IMG_VA_CUBE}; \
	export NBK_OUT_IMG=${NBK_OUT_IMG_VA_CUBE}; \
	export IDXR_INIT_BASE_IMG=${IDXR_INIT_BASE_IMG_VA_CUBE}

## Common ##

### Drone Paper Environment ###
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

drone-paper-restore-db: restore-db restore-local-data drone-paper-docker-commit

drone-paper-full-init: create-odc-db-volume create-notebook-volume drone-paper-up drone-paper-restore-db

drone-paper-full-down: drone-paper-down delete-odc-db-volume delete-notebook-volume
### End Drone Paper Environment ###

### ODC Training Environment ###
odc-training-config:
	${ODC_TRAINING_ENV_EXPRTS}; $(docker_compose) config

odc-training-build:
	${ODC_TRAINING_ENV_EXPRTS}; $(docker_compose) build

# Start the notebooks environment
odc-training-up:
	${ODC_TRAINING_ENV_EXPRTS}; $(docker_compose) up -d --build

# Start without rebuilding the Docker image
# (use when dependencies have not changed for faster starts).
odc-training-up-no-build:
	${ODC_TRAINING_ENV_EXPRTS}; $(docker_compose) up -d

# Stop the notebooks environment
odc-training-down:
	${ODC_TRAINING_ENV_EXPRTS}; $(docker_compose) down --remove-orphans

odc-training-restart: odc-training-down odc-training-up

odc-training-restart-no-build: odc-training-down odc-training-up-no-build

odc-training-docker-commit:
	docker commit docker_notebooks_1 ${NBK_OUT_IMG_ODC_TRAINING}

odc-training-restore-db: restore-db restore-local-data odc-training-docker-commit

odc-training-full-init: create-odc-db-volume create-notebook-volume odc-training-up odc-training-restore-db

odc-training-full-down: odc-training-down delete-odc-db-volume delete-notebook-volume
### End ODC Training Environment ###

### Google Earth Engine Environment ###
va-cube-config:
	${VA_CUBE_ENV_EXPRTS}; $(docker_compose) config

va-cube-build:
	${VA_CUBE_ENV_EXPRTS}; $(docker_compose) build

# Start the notebooks environment
va-cube-up:
	${VA_CUBE_ENV_EXPRTS}; $(docker_compose) up -d --build

# Start without rebuilding the Docker image
# (use when dependencies have not changed for faster starts).
va-cube-up-no-build:
	${VA_CUBE_ENV_EXPRTS}; $(docker_compose) up -d

# Stop the notebooks environment
va-cube-down:
	${VA_CUBE_ENV_EXPRTS}; $(docker_compose) down --remove-orphans

va-cube-restart: va-cube-down va-cube-up

va-cube-restart-no-build: va-cube-down va-cube-up-no-build

va-cube-docker-commit:
	docker commit docker_notebooks_1 ${NBK_OUT_IMG_VA_CUBE}

va-cube-restore-db: restore-db va-cube-docker-commit

va-cube-full-init: create-odc-db-volume create-notebook-volume va-cube-up va-cube-restore-db

va-cube-full-down: va-cube-down delete-odc-db-volume delete-notebook-volume
### End Google Earth Engine Environment ###

# List the running containers.
ps:
	$(docker_compose) ps
## End Common ##

## Notebooks ##
# Start an interactive shell to the notebooks container.
notebooks-ssh:
	$(docker_compose) exec notebooks bash

# Create the persistent volume for the ODC database.
create-notebook-volume:
	docker volume create odc-platform-notebook-vol

# Delete the persistent volume for the ODC database.
delete-notebook-volume:
	docker volume rm odc-platform-notebook-vol

recreate-notebook-volume: delete-notebook-volume create-notebook-volume
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

restore-local-data:
#	Copy compressed data from the indexer container to the 
#   notebooks container and decompress it.
	mkdir -p tmp
	docker cp docker_indexer_1:/Datacube/data.tar.gz tmp
	docker cp tmp/data.tar.gz docker_notebooks_1:/Datacube/data.tar.gz
	$(docker_compose) exec notebooks bash -c \
	  "mkdir /Datacube/data; \
	   tar -xzf /Datacube/data.tar.gz -C /Datacube/data; \
	   rm /Datacube/data.tar.gz"
	rm -rf tmp
## End Database ##

## Misc ##
sudo-ubuntu-install-docker:
	sudo apt-get update
	sudo apt install -y docker.io
	sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	sudo systemctl start docker
	sudo systemctl enable docker
	# The following steps are for enabling use 
	# of the `docker` command for the current user
	# without using `sudo`
	getent group docker || sudo groupadd docker
	sudo usermod -aG docker ${USER}

dkr-sys-prune:
	yes | docker system prune
## End Misc ##
