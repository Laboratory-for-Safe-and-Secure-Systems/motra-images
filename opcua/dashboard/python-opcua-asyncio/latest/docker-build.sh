#!/usr/bin/env bash
# PROFILES: sim, ot, opcua
# DESCRIPTION: Python Dashboard to visualize the current water plant simulation


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t dashboard