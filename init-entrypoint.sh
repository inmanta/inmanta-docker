#!/usr/bin/env bash
# Alternative entrypoint for the inmanta orchestrator container.
# Instead of starting the orchestrator, it clones a module and runs one of its
# test case.  This test case is expected to use pytest-inmanta-lsm to initialize
# the orchestrator.

set -x
set -e
set -o allexport

## INPUTS ##
# Load the input parameters, specifying which module to load and the test to
# run in order to initialize the orchestrator
INMANTA_MODULE_REPO_URL="${INMANTA_MODULE_REPO_URL}"
INMANTA_MODULE_REPO_BRANCH="${INMANTA_MODULE_REPO_BRANCH}"
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

# Make sure the module source is cloned on the host
[ -d /tmp/module ] || git clone -b "${INMANTA_MODULE_REPO_BRANCH}" "${INMANTA_MODULE_REPO_URL}" /tmp/module
cd /tmp/module
git checkout master && git pull

# Install sudo in the container
apt-get install -y sudo

# Create a virtual environment to install the module and its dependencies
[ -d venv ] || /opt/inmanta/bin/python -m venv venv

# Install the module and its dependencies
touch requirements.dev.txt requirements.txt
venv/bin/pip install -e /tmp/module -c requirements.txt -r requirements.dev.txt

# Use pytest-inmanta-lsm, installed in the venv, to initialize the orchestrator
export INMANTA_LSM_CONTAINER_ENV="true"
export INMANTA_LSM_NO_HALT="true"
export INMANTA_LSM_NO_CLEAN="true"
export INMANTA_LSM_REMOTE_SHELL="sudo -i -u"
export INMANTA_LSM_REMOTE_HOST="inmanta"
exec venv/bin/pytest $INMANTA_PYTEST_ARGUMENTS
