#!/usr/bin/env bash
# PROFILES: sim, ot, opcua
# DESCRIPTION: Python based watertank simulation backend


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t water-tank-simulation