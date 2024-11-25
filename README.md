# inmanta-docker

## Configuration

The examples of orchestrator setup using docker referenced below can be configured using some environment variables, they are documented in the table below.  The environment variables are to be provided to docker compose itself, they are not exposed directly to the processes running inside the containers.

| **Name** | **Default** | **Description** |
| --- | --- | --- |
| `INMANTA_ORCHESTRATOR_IMAGE` | / | **Required** This environment variable specifies which container image the orchestrator (and ssh sidecar) should use. |
| `POSTGRESQL_VERSION` | `14` | The postgresql version for the db container, the version should match the one required by the orchestrator version in use. |
| `INMANTA_AUTHORIZED_KEYS` | / | The public keys to insert into the ssh sidecar authorized keys for the inmanta user. |


## Deploy the oss orchestrator

```
# Latest oss release
export INMANTA_ORCHESTRATOR_IMAGE=ghcr.io/inmanta/orchestrator:latest

# Start db and orchestrator
sudo docker compose up -d

# Stop db and orchestrator
sudo docker compose down

# Clear storage or db and orchestrator
sudo docker compose down -v
```

## Deploy the oss orchestrator with an ssh sidecar

:bulb: **To give access to your used in the ssh sidecar, you must provide some public key that will be installed in the container.  You can do this using the INMANTA_AUTHORIZED_KEYS environment variable.**

```
# Latest oss release
export INMANTA_ORCHESTRATOR_IMAGE=ghcr.io/inmanta/orchestrator:latest

# Your own, new-line separated, public key(s)
export INMANTA_AUTHORIZED_KEYS="ssh-rsa ..."

# Start db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.ssh.override.yml up -d

# Stop db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.ssh.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.ssh.override.yml down -v
```

## Deploy the service orchestrator

:warning: **Prior to deploying the service orchestrator, you must setup access to the private container registry and place the license and entitlement files in the license folder.**

```
# Latest iso release
export INMANTA_ORCHESTRATOR_IMAGE=containers.inmanta.com/containers/service-orchestrator:8

# Start db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml up -d

# Stop db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml down -v
```

## Deploy the service orchestrator with an ssh sidecar

:warning: **Prior to deploying the service orchestrator, you must setup access to the private container registry and place the license and entitlement files in the license folder.**

:bulb: **To give access to your used in the ssh sidecar, you must provide some public key that will be installed in the container.  You can do this using the INMANTA_AUTHORIZED_KEYS environment variable.**

```
# Latest iso release
export INMANTA_ORCHESTRATOR_IMAGE=containers.inmanta.com/containers/service-orchestrator:8

# Your own, new-line separated, public key(s)
export INMANTA_AUTHORIZED_KEYS="ssh-rsa ..."

# Start db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml up -d

# Stop db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml down -v
```
