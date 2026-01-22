#!/usr/bin/env bash
# PROFILES: sim, opcua, ot
# DESCRIPTION: OPC UA Python historian

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
SERVER_URI=${SERVER_URI:-""} 

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"historian"}

docker build \
    --build-context     container_context=$CONTAINER_CONTEXT \
    . \
    -t $DOCKER_BUILD_TAG