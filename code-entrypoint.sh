#!/usr/bin/env bash
# Alternative entrypoint for the inmanta orchestrator container.
# Instead of starting the orchestrator, it clones a module and runs one of its
# test case.  This test case is expected to use pytest-inmanta-lsm to initialize
# the orchestrator.

set -x
set -e
set -o allexport

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

# Install sudo in the container
apt-get install -y sudo

# Install the code-server and relevant extensions
curl -fsSL https://code-server.dev/install.sh | sh
sudo -u inmanta code-server --install-extension ms-python.python
curl https://packages.inmanta.com/public/quickstart/raw/names/inmanta.inmanta.vsix/versions/1.7.0/inmanta-1.7.0.vsix -o /tmp/inmanta.inmanta.vsix
sudo -u inmanta code-server --install-extension /tmp/inmanta.inmanta.vsix

# Start the code-server
exec sudo -u inmanta code-server --bind-addr 0.0.0.0:8080 --auth none
