#!/usr/bin/env bash
# PROFILES: web, ot
# DESCRIPTION: A simple mongoose embedded web server  


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
USERNAME=${USERNAME:-"motra"}
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"mongoose"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t $DOCKER_BUILD_TAG