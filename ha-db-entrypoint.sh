#!/usr/bin/env bash
set -Eeuo pipefail

#
# Based on example: https://github.com/docker-library/postgres/blob/06388fc682dfe9c6008093d04b467581990e0c26/docker-ensure-initdb.sh
#
# Extend normal setup to setup the replica username and password before enabling the sync commits
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
	docker_verify_minimum_env
	docker_error_old_databases

	# check dir permissions to reduce likelihood of half-initialized database
	ls /docker-entrypoint-initdb.d/ > /dev/null

	docker_init_database_dir
	pg_setup_hba_conf "$@"

	# PGPASSWORD is required for psql when authentication is required for 'local' connections via pg_hba.conf and is otherwise harmless
	# e.g. when '--auth=md5' or '--auth-local=md5' is used in POSTGRES_INITDB_ARGS
	export PGPASSWORD="${PGPASSWORD:-$POSTGRES_PASSWORD}"
	docker_temp_server_start "$@"

	docker_setup_db
	docker_process_init_files /docker-entrypoint-initdb.d/*

    REPLICA_USERNAME="${POSTGRES_REPLICA_USER:?Postgres replica user name should be set}"
    REPLICA_PASSWORD="${POSTGRES_REPLICA_PASSWORD:?Postgres replica password should be set}"

    echo "CREATE USER ${REPLICA_USERNAME} WITH REPLICATION ENCRYPTED PASSWORD '${REPLICA_PASSWORD}';" | docker_process_sql
    echo "SELECT pg_create_physical_replication_slot('replication_slot');" | docker_process_sql

	docker_temp_server_stop
	unset PGPASSWORD
fi

REPLICA_APPNAME="${POSTGRES_REPLICA_APPNAME:?Postgres replica app name should be set}"

# proceed with normal startup, enable sync commit
exec "$@" -c synchronous_standby_names="${REPLICA_APPNAME}" -c wal_level=replica -c synchronous_commit=on -c hot_standby=off
