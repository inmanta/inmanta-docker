# inmanta-docker

This repo contains some example of docker based orchestrator deployments.  We illustrate here how to deploy both the open-source and the commercial edition, with or without an ssh sidecar (for ssh access to part of the orchestrator file system), with or without a logrotate sidecar (for rotating the logs generated by the orchestrator).

## Configuration

The examples of orchestrator setup using docker referenced below can be configured using some environment variables, they are documented in the table below.  The environment variables are to be provided to docker compose itself, they are not exposed directly to the processes running inside the containers.

| **Name** | **Default** | **Used by** | **Description** |
| --- | --- | --- | --- |
| `INMANTA_ORCHESTRATOR_IMAGE` | / | all | **Required** This environment variable specifies which container image the orchestrator (and ssh sidecar) should use. |
| `INMANTA_ORCHESTRATOR_IP` | `127.0.0.1` | `docker-compose.yml` | This environment variable specifies on which ip of the **host** the orchestrator api should be made available. |
| `INMANTA_ORCHESTRATOR_PORT` | `8888` | `docker-compose.yml` | This environment variable specifies on which port of the **host** the orchestrator api should be made available. |
| `POSTGRESQL_VERSION` | `16` | `docker-compose.yml` | The postgresql version for the db container, the version should match the one required by the orchestrator version in use. |
| `INMANTA_AUTHORIZED_KEYS` | / | `docker-compose.ssh.override.yml` | The public keys to insert into the ssh sidecar authorized keys for the inmanta user. |
| `INMANTA_SSH_SIDECAR_IP` | `127.0.0.1` | `docker-compose.ssh.override.yml` | This environment variable specifies on which ip of the **host** the ssh sidecar should be made available. |
| `INMANTA_SSH_SIDECAR_PORT` | `2222` | `docker-compose.ssh.override.yml` | This environment variable specifies on which port of the **host** the ssh sidecar should be made available. |

## Composition

The files in this repo allow to deploy the orchestrator with different topologies.  The desired topology should be composed by passing more or less `docker-compose.*.override.yml` files to docker compose.  The file `docker-compose.yml` should always be provided.

The docker compose commands can be summarized this way:
```bash
sudo docker compose \
    -f docker-compose.yml \
    [-f docker-compose.iso.override.yml] \ # Deploy service orchestrator instead of oss one
    [-f docker-compose.ssh.override.yml] \ # Deploy an ssh sidecar to access the orchestrator file system via ssh
    [-f docker-compose.logrotate.override.yml] \ # Deploy a logrotate sidecar to rotate the logs of the orchestrator
    <up|down|ps> [options...]
```

## Examples

### Deploy the oss orchestrator

```bash
# Latest oss release
export INMANTA_ORCHESTRATOR_IMAGE=ghcr.io/inmanta/orchestrator:latest

# Start db and orchestrator
sudo docker compose -f docker-compose.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml ps -a

# Stop db and orchestrator
sudo docker compose -f docker-compose.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml down -v
```

### Deploy the service orchestrator

:warning: **Prior to deploying the service orchestrator, you must setup access to the private container registry and place the license and entitlement files in the license folder.**

```bash
# Latest iso release
export INMANTA_ORCHESTRATOR_IMAGE=containers.inmanta.com/containers/service-orchestrator:8

# Start db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.override.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.iso.override.yml ps -a

# Stop db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.override.yml down -v
```

## Deploy the orchestrator with an ssh sidecar

:warning: **To give access to your used in the ssh sidecar, you must provide some public key that will be installed in the container.  You can do this using the INMANTA_AUTHORIZED_KEYS environment variable.**

```bash
export INMANTA_ORCHESTRATOR_IMAGE="..."

# Your own, new-line separated, public key(s)
export INMANTA_AUTHORIZED_KEYS="ssh-rsa ..."

# Start db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.override.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.override.yml ps -a

# Stop db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.override.yml down -v
```

> :bulb: **How to ssh inside the container?**
> 
> Once deployed, you can figure out the ip of the ssh sidecar by inspecting the ssh sidecar container: 
> ```
> docker inspect inmanta-ssh-sidecar`
> ```
> To ssh inside the container, you can then use this one liner:
> ```
> ssh inmanta@$(docker inspect -f '{{range .NetworkSettings.Networks}}{{print .IPAddress}}{{end}}' inmanta-ssh-sidecar)
> ```
> Alternatively, you can also ssh in the container using the bind port of the container on the host:
> ```
> ssh -p "${INMANTA_SSH_SIDECAR_PORT:-2222}" "inmanta@${INMANTA_SSH_SIDECAR_IP:-127.0.0.1}"
> ```

## Deploy the orchestrator with a logrotate sidecar

:bulb: The health check of the logrotate container may stay in the starting state for a very long time (up to 24h) as it checks that logrotate did run, which happens only once a day.

```bash
export INMANTA_ORCHESTRATOR_IMAGE="..."

# Start db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.override.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.override.yml ps -a

# Stop db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.override.yml down

# Clear storage of db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.override.yml down -v
```
