| :warning:  Warning   |
|:---------------------|
| This environment is currently inoperable. We will remove this notice when the problems have been resolved. |

# Open Data Cube Platform

The AMA ([Analytical Mechanics Associates](https://www.ama-inc.com/)) Open Data Cube Platform is a [Jupyter Notebook](https://jupyter.org/) environment that uses the [Open Data Cube](https://www.opendatacube.org/) to analyze satellite data.

Each user should receive their own exclusive (not shared) environment. Each user's server will be created from a clone of this repository.

## Contents

* [Starting the Environment](#start-env)
* [Running the Environment](#run-env)
* [Training Plan](#train-plan)
<br><br>

## <a name="start-env"></a> Starting the Environment

First, ensure you are running in a Linux environment.

Next, ensure you can run the `make` command. For Ubuntu, you can run `apt-get install build-essential` to install Make.

Now you can change some settings before starting the environment:
In `build/docker/.env`, you can change `HOST_PORT` and `NBK_SERVER_PASSWORD` to values you like - with `HOST_PORT` being the port to run the notebook server on and `NBK_SERVER_PASSWORD` being the password.

Now run this command to initialize the environment:

`make create-odc-db-volume drone-paper-up restore-db`

This may take several minutes. Most of this time is spent restoring the index database.

Once the preceding command completes, try connecting to the notebook server at `localhost:{HOST_PORT}`. By default, that should be `localhost:8081`.

Enter the string specified in `NBK_SERVER_PASSWORD` in the "Password or token" field at the top of the page and then click the "Log in" button to the right of it.

## <a name="run-env"></a> Running the Environment

To start the environment, run `make drone-paper-up`.

To stop the environment, run `make drone-paper-down`.

To restart the environment, run `make drone-paper-restart` (same as `make drone-paper-down drone-paper-up` or `make drone-paper-down; make drone-paper-up`).

To check if the environment is running, run `make ps`.

To connect to the notebook server container through a bash shell, run `make notebooks-ssh`.

To connect to the indexer container through a bash shell, run `make indexer-ssh`.

To connect to the database container through a bash shell, run `make db-ssh`.

## <a name="train-plan"></a> Training Plan

