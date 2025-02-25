# inmanta-docker

This repo contains some example of docker based orchestrator deployments.  We illustrate here how to deploy both the open-source and the commercial edition, with or without an ssh sidecar (for ssh access to part of the orchestrator file system), with or without a logrotate sidecar (for rotating the logs generated by the orchestrator).

**Quick access:**
- [Deploy the open source orchestrator](#deploy-the-oss-orchestrator)
- [Deploy the service orchestrator](#deploy-the-service-orchestrator)
- [Deploy the orchestrator with ssh access](#deploy-the-orchestrator-with-an-ssh-sidecar)
- [Deploy the orchestrator with log rotation](#deploy-the-orchestrator-with-a-logrotate-sidecar)

## Configuration

The examples of orchestrator setup using docker referenced below can be configured using some environment variables, they are documented in the table below.  The environment variables are to be provided to docker compose itself, they are not exposed directly to the processes running inside the containers.  To do so, you can either save them in a file named `.env` in the current directory, or export them in the current shell and pass them on to `docker compose` using the `--env` option, taking as argument the name of the environment variable `docker compose` should read.

| **Name** | **Default** | **Used by** | **Description** |
| --- | --- | --- | --- |
| `INMANTA_ORCHESTRATOR_IMAGE` | `ghcr.io/inmanta/orchestrator:latest` | all | This environment variable specifies which container image the orchestrator (and sidecars) should use. |
| `INMANTA_ORCHESTRATOR_IP` | `127.0.0.1` | `docker-compose.yml` | This environment variable specifies on which ip of the **host** the orchestrator api should be made available. |
| `INMANTA_ORCHESTRATOR_PORT` | `8888` | `docker-compose.yml` | This environment variable specifies on which port of the **host** the orchestrator api should be made available. |
| `POSTGRESQL_VERSION` | `16` | `docker-compose.yml` | The postgresql version for the db container, the version should match the one required by the orchestrator version in use. |
| `INMANTA_AUTHORIZED_KEYS` | / | `docker-compose.ssh.yml` | The public keys to insert into the ssh sidecar authorized keys for the inmanta user. |
| `INMANTA_SSH_SIDECAR_IP` | `127.0.0.1` | `docker-compose.ssh.yml` | This environment variable specifies on which ip of the **host** the ssh sidecar should be made available. |
| `INMANTA_SSH_SIDECAR_PORT` | `2222` | `docker-compose.ssh.yml` | This environment variable specifies on which port of the **host** the ssh sidecar should be made available. |
| `INMANTA_MODULE_REPO_URL` | / | `docker-compose.init.yml` | This environment variable specifies the url of the git repo containing the init test case. |
| `INMANTA_MODULE_REPO_BRANCH` | `master` | `docker-compose.init.yml` | This environment variable specifies the branch of the git repo containing the init test case. |
| `INMANTA_PYTEST_ARGUMENTS` | `tests` | `docker-compose.init.yml` | This environment variable specifies the arguments to give to pytest when running the initialization tests. |

## Composition

The files in this repo allow to deploy the orchestrator with different topologies.  The desired topology should be composed by passing more or less `docker-compose.*.yml` files to docker compose.  The file `docker-compose.yml` should always be provided.

The docker compose commands can be summarized this way:
```
sudo docker compose
    -f docker-compose.yml
    [-f docker-compose.iso.yml]  # Deploy service orchestrator instead of oss one
    [-f docker-compose.ssh.yml]  # Deploy an ssh sidecar to access the orchestrator file system via ssh
    [-f docker-compose.logrotate.yml]  # Deploy a logrotate sidecar to rotate the logs of the orchestrator
    [-f docker-compose.init.yml] # Deploy a temporary sidecar, which can run a test case of a module to initialize the orchestrator
    <up|down|ps> [options...]
```

## Examples

### Deploy the oss orchestrator

```bash
# Latest oss release
echo INMANTA_ORCHESTRATOR_IMAGE=ghcr.io/inmanta/orchestrator:latest >> .env

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

:warning: **Prior to deploying the service orchestrator, you must setup access to the private container registry and place the license and entitlement files in the license folder.  In this example, these license files should be named `license/example.com.license` and `license/example.com.jwe`.**

```bash
# Latest iso release
echo "INMANTA_ORCHESTRATOR_IMAGE=containers.inmanta.com/containers/service-orchestrator:8" >> .env

# Copy the license files in the license folder
cp "..." license/example.com.license
cp "..." license/example.com.jwe

# Start db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml ps -a

# Stop db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml down -v
```

### Deploy the orchestrator with an ssh sidecar

:warning: **To give access to your used in the ssh sidecar, you must provide some public key that will be installed in the container.  You can do this using the INMANTA_AUTHORIZED_KEYS environment variable.**

```bash
echo "INMANTA_ORCHESTRATOR_IMAGE=..." >> .env

# Your own, new-line separated, public key(s)
echo "INMANTA_AUTHORIZED_KEYS=ssh-rsa ..." >> .env

# Start db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.yml ps -a

# Stop db, orchestrator and ssh sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.yml down

# Clear storage or db and orchestrator
sudo docker compose -f docker-compose.yml -f docker-compose.ssh.yml down -v
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

### Deploy the orchestrator with a logrotate sidecar

:bulb: The health check of the logrotate container will check that logrotate has inmanta in its status file.  This status file is only created after the first logrotate execution, which may happen anytime in the first 24h of the container lifetime.  To avoid keeping the container in a "starting" health for 24h, until the status file is visible, we rather check for the existence of the logrotate binary.

```bash
echo "INMANTA_ORCHESTRATOR_IMAGE=..." >> .env

# Start db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.yml ps -a

# Stop db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.yml down

# Clear storage of db, orchestrator and logrotate sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.logrotate.yml down -v
```

### Deploy the service orchestrator with an init sidecar

:bulb: When developing a module, it is not uncommon to have a test case based on [pytest-inmanta-lsm](https://github.com/inmanta/pytest-inmanta-lsm) which resets an environment of a running orchestrator and deploys the model of the module, containing the service definition defined in the module.  Such test case can easily be used to initialize an orchestrator with the given project, for **development purposes**.

```bash
echo "INMANTA_ORCHESTRATOR_IMAGE=..." >> .env
echo "INMANTA_MODULE_REPO_URL=..." >> .env
echo "INMANTA_MODULE_REPO_BRANCH=..." >> .env
echo "INMANTA_PYTEST_ARGUMENTS=..." >> .env

# Start db, service orchestrator and init sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml -f docker-compose.init.yml up -d

# Check the containers status
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml -f docker-compose.init.yml ps -a

# Stop db, service orchestrator and init sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml -f docker-compose.init.yml down

# Clear storage of db, service orchestrator and init sidecar
sudo docker compose -f docker-compose.yml -f docker-compose.iso.yml -f docker-compose.init.yml down -v
```

## Rationale

:bulb: **Why do we use sidecars?**  

We believe that when running applications in containers, one should limit itself to have one application by container.  We also believe that containers should ideally be as light as possible, and shouldn't contain anything that is not required by the application running inside it.  But we also believe that running the orchestrator in a container shouldn't come with too many limitations (such as losing ssh access, log rotation, etc).  This is why we propose you to run other containers alongside the orchestrator, to deploy applications related to the orchestrator, but which don't belong within the orchestrator container itself.  We call these containers "sidecars".

:bulb: **Why use the orchestrator image for the sidecars?**  

The sidecar containers share some part of the orchestrator file system using volumes.  These shared folders are owned by the inmanta user, in the orchestrator container.  Docker doesn't provide a very convenient way of remapping users from the container to the host (like podman does with `--uidmap/--gidmap`), meaning that if the folder are owned by the inmanta user, with specific uid and gid, we **must** use the same uid and gid in the other containers accessing the volume, and ideally we **should** use the same user name, to keep things clear.  For this reason, we decided to keep the orchestrator image as a base for the sidecar, and simply install in these sidecar the additional dependencies we need, ensuring the uid and git stay consistent across the different containers.
