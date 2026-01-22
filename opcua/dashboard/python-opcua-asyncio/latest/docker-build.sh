#!/usr/bin/env bash
# PROFILES: sim, ot, opcua
# DESCRIPTION: Python Dashboard to visualize the current water plant simulation


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"dashboard"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t $DOCKER_BUILD_TAG