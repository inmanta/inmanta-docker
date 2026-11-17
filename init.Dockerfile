# Build an init container, which runs a test case of a module to initialize the orchestrator.
# The module and its python dependencies are installed in the image, so they are only
# installed again when the module source changes.
ARG INMANTA_ORCHESTRATOR_IMAGE
FROM ${INMANTA_ORCHESTRATOR_IMAGE}

LABEL com.inmanta.description="Init container for ${INMANTA_ORCHESTRATOR_IMAGE}"

# Setup and entrypoint must run as root
USER root:root

RUN <<BUILD_EOF
set -x
set -e

apt-get update
apt-get install -y sudo
rm -rf /var/lib/apt/lists/*
BUILD_EOF

COPY --from=ghcr.io/astral-sh/uv:0.13.5 /uv /usr/local/bin/uv

# Index and pre-release policy used to install the module dependencies
ARG UV_DEFAULT_INDEX=https://pypi.org/simple
ARG UV_PRERELEASE=if-necessary-or-explicit

# The module is installed in a venv using the python of the orchestrator
ENV VIRTUAL_ENV=/opt/module-venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV UV_LINK_MODE=copy
RUN uv venv --python /opt/inmanta/bin/python "${VIRTUAL_ENV}"

# The module source is provided as the "module" build context
COPY --from=module . /module
WORKDIR /module
RUN --mount=type=cache,target=/root/.cache/uv <<BUILD_EOF
set -x
set -e

touch requirements.txt requirements.dev.txt
uv pip install -e . -c requirements.txt -r requirements.dev.txt
BUILD_EOF

COPY init-entrypoint.sh /init-entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/init-entrypoint.sh"]
