#!/usr/bin/env bash
set -Eeuo pipefail

#
# Based on example: https://github.com/docker-library/postgres/blob/06388fc682dfe9c6008093d04b467581990e0c26/docker-ensure-initdb.sh
#
# Extend normal setup to setup the replica db
#

source /usr/local/bin/docker-entrypoint.sh

# arguments to this script are assumed to be arguments to the "postgres" server (same as "docker-entrypoint.sh"), and most "docker-entrypoint.sh" functions assume "postgres" is the first argument (see "_main" over there)
if [ "$#" -eq 0 ] || [ "$1" != 'postgres' ]; then
	set -- postgres "$@"
fi

# see also "_main" in "docker-entrypoint.sh"

docker_setup_env
# setup data directories and permissions (when run as root)
docker_create_db_directories
if [ "$(id -u)" = '0' ]; then
	# then restart script as postgres user
	exec gosu postgres "$BASH_SOURCE" "$@"
fi

# only run initialization on an empty data directory
if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
	docker_error_old_databases

	# check dir permissions to reduce likelihood of half-initialized database
	ls /docker-entrypoint-initdb.d/ > /dev/null

	until pg_basebackup --pgdata=$PGDATA -R --slot=replication_slot
	do
	echo 'Waiting for primary to connect...'
	sleep 1s
	done
	echo 'Backup done, starting replica...'
fi

# proceed with normal startup, enable sync commit
exec "$@"
