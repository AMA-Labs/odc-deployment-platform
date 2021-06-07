# Open Data Cube Platform

The AMA ([Analytical Mechanics Associates](https://www.ama-inc.com/)) Open Data Cube Platform is a [Jupyter Notebook](https://jupyter.org/) environment that uses the [Open Data Cube](https://www.opendatacube.org/) to analyze satellite data.

Each user should receive their own exclusive (not shared) environment. Each user's server will be created from a clone of this repository.

## Contents

* [Starting the Environment](#start-env)
* [Running the Environment](#run-env)
* [Deleting the Environment](#delete-env)
<br><br>

## <a name="start-env"></a> Starting the Environment

First, ensure you are running in a Linux environment.

Next, ensure you can run the `make` command. For Ubuntu, you can run `apt-get install build-essential` to install Make.

Now you can change some settings before starting the environment:
In `build/docker/.env`, you can change `HOST_PORT` and `NBK_SERVER_PASSWORD` to values you like - with `HOST_PORT` being the port to run the notebook server on and `NBK_SERVER_PASSWORD` being the password.

Now run this command to initialize the environment:

`make <env-prefix>-full-init`

Where `<env-prefix>` is the prefix for the environment, like `drone-paper` for the IGARSS 2021 drone data ODC pipeline paper (titled "An End-to-end Pipeline for Acquiring, Processing, and Importing UAS Data for Use in the Open Data Cube (ODC)"). You can examine the `Makefile` for available environments.

This may take a few minutes. Most of this time is spent restoring the index database.

Once the preceding command completes, try connecting to the notebook server at `localhost:{HOST_PORT}`. By default, that should be `localhost:8081`.

Enter the string specified in `NBK_SERVER_PASSWORD` in the "Password or token" field at the top of the page and then click the "Log in" button to the right of it.

## <a name="stop-env"></a> Running the Environment

To start the environment, run `make <env-prefix>-up`.

To stop the environment, run `make <env-prefix>-down`.

To restart the environment, run `make <env-prefix>-restart` (same as `make <env-prefix>-down <env-prefix>-up` or `make <env-prefix>-down; make <env-prefix>-up`).

To check if the environment is running, run `make ps`.

To connect to the notebook server container through a bash shell, run `make notebooks-ssh`.

To connect to the indexer container through a bash shell, run `make indexer-ssh`.

To connect to the database container through a bash shell, run `make db-ssh`.

## <a name="delete-env"></a> Deleting the Environment

When you are fully done with the environment, including all content in it, run this command to remove everything in it.

`make <env-prefix>-full-down`

| :warning:  Warning   |
|:---------------------|
| Any content you have in your environment will be permanently deleted after running this comment. This includes any indexed data and any filesystem state in the notebook server, including notebooks. |
