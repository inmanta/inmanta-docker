# inmanta-docker

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

```
# Latest oss release
export INMANTA_ORCHESTRATOR_IMAGE=ghcr.io/inmanta/orchestrator:latest

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

```
# Latest iso release
export INMANTA_ORCHESTRATOR_IMAGE=containers.inmanta.com/containers/service-orchestrator:8

# Start db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml up -d

# Stop db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker.compose.iso.override.yml -f docker-compose.ssh.override.yml down -v
```
