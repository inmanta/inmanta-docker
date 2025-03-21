#!/usr/bin/env bash
# Alternative entrypoint for the inmanta orchestrator container.
# Instead of starting the orchestrator, it starts an ssh daemon, to allow
# remote access to some volumes shared with the actual orchestrator.

set -x
set -e

## INPUTS ##
# Get the public key which should be inserted into the authorized keys file of
# the inmanta user
INMANTA_USER_AUTHORIZED_KEYS="${INMANTA_AUTHORIZED_KEYS}"


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

# Configure ssh server
apt-get update
apt-get install -y openssh-server
ssh-keygen -A

# Configure the inmanta user remote access
mkdir -p "$INMANTA_USER_HOME_DIR/.ssh"
chmod 700 "$INMANTA_USER_HOME_DIR" "$INMANTA_USER_HOME_DIR/.ssh"
touch "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"
if [ "$INMANTA_USER_AUTHORIZED_KEYS" != "" ]; then
    echo "$INMANTA_USER_AUTHORIZED_KEYS" > "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"
fi
chown -R inmanta:inmanta "$INMANTA_USER_HOME_DIR"
chmod 600 "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"

# Create an ssh key for local usage (healthcheck)
[ -f /root/.ssh/id_rsa ] || ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa
grep "$(cat /root/.ssh/id_rsa.pub)" "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys" || cat /root/.ssh/id_rsa.pub >> "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"

# Start the ssh server, make it become the main process
mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
