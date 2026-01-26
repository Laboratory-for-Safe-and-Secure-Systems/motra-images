FROM python:3.10 AS base

# configure the main environment for build and release here
# optionally additional environment can be passed in using docker 
# remember to set the poetry version to a fixed version number!
ARG CUSTOM_ENV
ENV CUSTOM_ENV=${CUSTOM_ENV} \
  PYTHONFAULTHANDLER=1 \
  PYTHONUNBUFFERED=1 \
  PYTHONHASHSEED=random \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  SHELL="/bin/bash" \
  # Poetry's configuration:
  POETRY_NO_INTERACTION=1 \
  POETRY_VIRTUALENVS_CREATE=true \
  POETRY_CACHE_DIR='/opt/cache/pypoetry' \
  POETRY_HOME='/opt/poetry' \
  POETRY_VERSION=2.1.2  

# venv is a needed dependency for poetry and the installer to resove dependencies outside of poetry
# update required packages and clean artifacts before 
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
    libssl-dev \
    netcat-openbsd \
    # python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
   
# prepare the python installation and install dependencies inside the poetry cache
FROM base AS builder

# the workdir must be identical between builder and runtime container, otherwise poetry cache wont work when 
# copying the files between both images!
WORKDIR /usr/src/app

# install poetry and base dependencies
# optionally include the lock file if existing
COPY --from=container_context README.md src/pyproject.toml src/poetry.loc[k] /usr/src/app/
RUN mkdir /opt/poetry && \ 
          python3 -m venv $POETRY_HOME && \
          $POETRY_HOME/bin/pip install poetry==$POETRY_VERSION && \
          $POETRY_HOME/bin/poetry --version && \
          $POETRY_HOME/bin/poetry install --no-root 

# move the cached files into the runner and reinitiate the core dependencies using poetry
FROM base AS runtime
WORKDIR /usr/src/app

# setup the server and the model files
ARG EXEC_MODE=775
ARG NODESET_MODEL="FullSystem.NodeSet2.xml"
COPY --from=builder /opt /opt
COPY --from=container_context --chmod=$EXEC_MODE    entrypoint.sh       entrypoint.sh
COPY --from=container_context                       src/pyproject.toml  pyproject.toml
COPY --from=container_context                       README.md           README.md
COPY --from=container_context                       src/server.py       server.py
COPY --from=nodeset_context                         $NODESET_MODEL      Server.NodeSet2.xml
COPY --from=companion_context                       *                   /schemas/

# will be executed on startup, parameters will be shared by docker/github 
# using basic shared environment variables 
ENTRYPOINT ["/usr/bin/env"]
CMD ["./entrypoint.sh"]
