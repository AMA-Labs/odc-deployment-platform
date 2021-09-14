# Open Data Cube Platform

The AMA ([Analytical Mechanics Associates](https://www.ama-inc.com/)) Open Data Cube Platform allows creation of pre-defined [JupyterLabs](https://jupyter.org/) environments that use the [Open Data Cube](https://www.opendatacube.org/) to analyze earth observation data. Each pre-defined environment is paired with an ODC index database that has some products and indexed data for those products relevant to that environment.

Each user should receive their own exclusive (not shared) environment. Each user's server will be created from a copy of this repository.

## Contents

* [Starting an Environment](#start-env)
* [Managing a Running Environment](#manage-env)
* [Destroying an Environment](#destroy-env)
* [Defining an Environment](#define-env)
<br><br>

## <a name="start-env"></a> Starting an Environment

First, ensure you are running in a Linux environment.

Next, ensure you can run the `make` command. For Ubuntu, you can run `sudo apt-get update -y; sudo apt-get install build-essential -y` to install Make.

Now you need to install Docker and Docker Compose. On Ubuntu, you can run this command to install both:
`make sudo-ubuntu-install-docker`
If you are not on Ubuntu, you should be able to install Docker following [these instructions](https://docs.docker.com/engine/install/) and Docker Compose following [these instructions](https://docs.docker.com/compose/install/).

Now you can change some settings before starting an environment:
In `build/docker/.env`, you can change `HOST_PORT` and `NBK_SERVER_PASSWORD` to values you like - with `HOST_PORT` being the port to run the notebook server on and `NBK_SERVER_PASSWORD` being the password.

If you want to load remote data, you will need to set the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables in the terminal context that will run the environment so that environment can see them. If the environment is already running, you will need to run the `restart` command for it to see your AWS credentials.

| :exclamation:  ODC-GEE Environments |
|-----------------------------------------|
|For environments that use [the CEOS ODC-GEE project](https://github.com/ceos-seo/odc-gee) to load data from Google Earth Engine (GEE), you must put your GEE service account private key JSON file in `odc_gee/config/credentials.json` to allow loading of GEE data. Follow [these instructions](https://developers.google.com/earth-engine/guides/service_account) to create a service account private key.<br><br>You can optionally create a JSON file for storing latitude/longitude locations if not performing global indexing. This file is stored at `odc_gee/config/regions.json`. See [this file](https://github.com/ceos-seo/odc-gee/blob/master/opt/config/odc-gee/regions.json) for an example.|

Now run this command to initialize the environment:

`make <env-prefix>-full-init`

Where `<env-prefix>` is the prefix for the environment, like `drone-paper` for the IGARSS 2021 drone data ODC pipeline paper (titled "An End-to-end Pipeline for Acquiring, Processing, and Importing UAS Data for Use in the Open Data Cube (ODC)"). You can examine the `Makefile` for available environments. Currently they are:

* `drone-paper`
* `odc-training`

So for example, `make drone-paper-full-init` will deploy the 
drone environment.

This may take a few minutes. Most of this time is spent restoring the index database.

Once the preceding command completes, try connecting to the notebook server at `localhost:{HOST_PORT}`. By default, that should be `localhost:8081`.

Enter the string specified in `NBK_SERVER_PASSWORD` in the "Password or token" field at the top of the page and then click the "Log in" button to the right of it.

## <a name="manage-env"></a> Managing a Running Environment

To start an environment, run `make <env-prefix>-up`.

To stop an environment, run `make <env-prefix>-down`.

To restart an environment, run `make <env-prefix>-restart` (same as `make <env-prefix>-down <env-prefix>-up` or `make <env-prefix>-down; make <env-prefix>-up`).

To check if an environment is running, run `make ps`.

To connect to the notebook server container through a bash shell, run `make notebooks-ssh`.

To connect to the indexer container through a bash shell, run `make indexer-ssh`.

To connect to the database container through a bash shell, run `make db-ssh`.

## <a name="destroy-env"></a> Destroying an Environment

When you are fully done with an environment, including all content in it, run this command to remove everything in it.

`make <env-prefix>-full-down`

| :warning:  Warning   |
|:---------------------|
| Any content you have in your environment will be permanently deleted after running this command. This includes any filesystem state in the notebook server, such as notebooks and data. |

## <a name="define-env"></a> Defining an Environment
To define an environment, follow these steps:

1. In `Makefile` in the `Notebooks` section (denoted by "## Notebooks ##" ... "## End Notebooks ##"), copy an existing environment's subsection (e.g. "### Drone Paper ###" ... "### End Drone Paper ###") and rename the copy in both the block's comments (e.g. "### My Environment ###" ... "### End My Environment ###") and the variables defined in it (e.g. `NBK_BASE_IMG_REPO_DRONE_PAPER` becomes `NBK_BASE_IMG_REPO_MY_ENV`). 
2. Do similarly as in the above step for the environment's exports (e.g. `DRONE_PAPER_ENV_EXPRTS`) just above the `Common` section (denoted by "## Common ##" ... "## End Common ##" - a very large section).
3. In `Makefile` in the `Common` section, copy an existing environment's subsection (e.g. "### Drone Paper Environment ###" ... "### End Drone Paper Environment ###")) and rename the copy in both the block's comments (e.g. "### My Environment ###" ... "### End My Environment ###") and the targets - so replace the `<env-prefix>` portion of the targets with the name of the new environment you are defining (e.g. `drone-paper-full-init` becomes `my-env-full-init`).
4. To specify the data indexed, and possibly even data kept locally in the environment itself, use the [ODC DB Init](https://github.com/jcrattz/odc_db_init) repository.
