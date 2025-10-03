#!/usr/bin/env sh
# Alternative entrypoint for the postgresql container.
# Instead of starting a database, it starts a cron daemon, to allow
# pg_dump to periodically run and export a database dump.

set -x
set -e

# Install cron, logrotate and tini
apt-get update
apt-get install -y cron logrotate  tini

# Configure db dump script, save container env vars in script to simplify
# container configuration
if [ ! -f /db_dump ]; then
    cat > /db_dump <<EOF
#!/usr/bin/env sh
set -x
set -e
$(export)
pg_dump -f /var/lib/postgresql/data/db_dump.sql
EOF
	chmod 755 /db_dump
fi

# Use logrotate to keep multiple backups, compress them, and don't
# leak too much old data
if [ ! -f /etc/logrotate.d/postgres ]; then
    cat > /etc/logrotate.d/postgres <<EOF
/var/lib/postgresql/data/*.sql {
	daily
	compress
	rotate 10
	missingok
	create 0644 postgres postgres
    postrotate
    su -c /db_dump - postgres
    endscript
}
EOF
fi

# Make sure that no other cron job needs to be executed
rm /etc/cron.hourly/* -f
find /etc/cron.daily/ ! -name 'logrotate' -type f -exec rm -f {} +
rm /etc/cron.weekly/* -f
rm /etc/cron.monthly/* -f
rm /etc/cron.yearly/* -f

# Validate that the db_dump script works and generate a first dump
chown postgres -R /var/lib/postgresql/data
su -c /db_dump - postgres

# Run cron as a main process
exec /usr/bin/tini -- cron -f
