#!/usr/bin/env sh
# Alternative entrypoint for the inmanta orchestrator container.
# Instead of starting the orchestrator, it starts a cron daemon, to allow
# pg_dump to periodically run and export a database dump.

set -x
set -e

# Install and configure cron
apt-get update
apt-get install -y cron tini
if [ ! -f /etc/cron.daily/dump ]; then
    cat > /etc/cron.daily/dump <<EOF
#!/usr/bin/env sh
$(export)
pg_dump -f /var/lib/postgresql/data/backup.sql
EOF
	chmod 755 /etc/cron.daily/dump
fi

# Make sure that no other cron job needs to be executed
rm /etc/cron.hourly/* -f
find /etc/cron.daily/ ! -name 'dump' -type f -exec rm -f {} +
rm /etc/cron.weekly/* -f
rm /etc/cron.monthly/* -f
rm /etc/cron.yearly/* -f

# Run cron as a main process
exec /usr/bin/tini -- cron -f
