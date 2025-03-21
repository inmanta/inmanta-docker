#!/usr/bin/env bash
# Alternative entrypoint for the inmanta orchestrator container.
# Instead of starting the orchestrator, it starts a cron daemon, to allow
# logrotate to periodically run an compress the logs generated by the server.

set -x
set -e

# Configure cron and logrotate
apt-get update
apt-get install -y cron logrotate
if [ ! -f /etc/logrotate.d/inmanta ]; then
    cat > /etc/logrotate.d/inmanta <<EOF
$INMANTA_CONFIG_LOG_DIR/*.log $INMANTA_CONFIG_LOG_DIR/*.out $INMANTA_CONFIG_LOG_DIR/*.err {
	daily
	compress
	rotate 10
	missingok
	create 0644 inmanta inmanta
}
EOF
fi

# Run cron as a main process
exec cron -f
