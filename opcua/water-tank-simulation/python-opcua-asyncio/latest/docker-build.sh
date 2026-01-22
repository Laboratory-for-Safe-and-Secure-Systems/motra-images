#!/usr/bin/env bash
# PROFILES: sim, ot, opcua
# DESCRIPTION: Python based watertank simulation backend


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"water-tank-simulation"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t $DOCKER_BUILD_TAG