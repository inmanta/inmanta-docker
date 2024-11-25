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
# Configure inmanta cli, persist any of the provided environment variables
# in the user profile file
INMANTA_USER_HOME_DIR=$(getent passwd inmanta | cut -d: -f6)
export | grep INMANTA >> "${INMANTA_USER_HOME_DIR}/.profile"

# Configure ssh server
apt-get install -y openssh-server
if [ ! -f /etc/ssh/ssh_host_* ]; then
    ssh-keygen -A
fi

# Configure the inmanta user remote access
mkdir -p "$INMANTA_USER_HOME_DIR/.ssh"
chmod 700 "$INMANTA_USER_HOME_DIR" "$INMANTA_USER_HOME_DIR/.ssh"
echo "$INMANTA_USER_AUTHORIZED_KEYS" >> "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"
chown -R inmanta:inmanta "$INMANTA_USER_HOME_DIR"
chmod 600 "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"

# Create an ssh key for local usage (healthcheck)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> "$INMANTA_USER_HOME_DIR/.ssh/authorized_keys"

# Start the ssh server, make it become the main process
mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
