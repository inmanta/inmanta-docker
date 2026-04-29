# Build a logrotate container compatible with the inmanta service orchestrator
ARG INMANTA_ORCHESTRATOR_IMAGE
FROM ${INMANTA_ORCHESTRATOR_IMAGE}

LABEL com.inmanta.description="Logrotate container for ${INMANTA_ORCHESTRATOR_IMAGE}"

# Setup and entrypoint must run as root
USER root:root

RUN <<BUILD_EOF
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

# Make sure that no other cron job needs to be executed
rm /etc/cron.hourly/* -f
find /etc/cron.daily/ ! -name 'logrotate' -type f -exec rm -f {} +
rm /etc/cron.weekly/* -f
rm /etc/cron.monthly/* -f
rm /etc/cron.yearly/* -f
BUILD_EOF

VOLUME  ["/var/log/inmanta", "/var/lib/logrotate/"]

# Verify the logrotate status
HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=5 \
    CMD ["bash", "-c", "if [ -f /var/lib/logrotate/status ]; then grep inmanta /var/lib/logrotate/status; else which logrotate; fi"]

# Entrypoint is cron, which will be executing logrotate at regular interval
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/sbin/cron", "-f"]
