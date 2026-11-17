#!/usr/bin/env bash
# Entrypoint of the init container, built with init.Dockerfile.
# It runs one of the test cases of the module installed in the image.  This test
# case is expected to use pytest-inmanta-lsm to initialize the orchestrator.

set -x
set -e
set -o allexport

## INPUTS ##
# Load the input parameters, specifying the test to run in order to initialize
# the orchestrator
INMANTA_PYTEST_ARGUMENTS="${INMANTA_PYTEST_ARGUMENTS}"

## SETUP ##
# Make sure that any environment variable prefixed with INMANTA which is available
# to the container, will also be available to the inmanta user when login in
INMANTA_USER_HOME_DIR=$(getent passwd inmanta | cut -d: -f6)
INMANTA_ENV_FILE="${INMANTA_USER_HOME_DIR}/.inmanta_env"
INMANTA_PROFILE="${INMANTA_USER_HOME_DIR}/.profile"
LOAD_ENV_CMD=". $INMANTA_ENV_FILE"

# Overwrite environment variables in dedicated file
if export | grep INMANTA; then
    export | grep INMANTA > $INMANTA_ENV_FILE
fi

# Make sure to load environment variables when login in
touch $INMANTA_PROFILE
grep -e "$LOAD_ENV_CMD" "$INMANTA_PROFILE" || echo "$LOAD_ENV_CMD" >> "$INMANTA_PROFILE"

# Use pytest-inmanta-lsm, installed in the venv of the image, to initialize the orchestrator
export INMANTA_LSM_CONTAINER_ENV="true"
export INMANTA_LSM_NO_HALT="true"
export INMANTA_LSM_NO_CLEAN="true"
export INMANTA_LSM_REMOTE_SHELL="sudo -i -u"
export INMANTA_LSM_REMOTE_HOST="inmanta"
exec pytest $INMANTA_PYTEST_ARGUMENTS
