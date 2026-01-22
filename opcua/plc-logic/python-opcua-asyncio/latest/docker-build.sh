#!/usr/bin/env bash
# PROFILES: sim, opcua, ot
# DESCRIPTION: OPC UA PLC server

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
PS_URI=${PS_URI:-"opc.tcp://localhost:4840"}
LSS_URI=${LSS_URI:-"opc.tcp://localhost:4841"}
VS_URI=${VS_URI:-"opc.tcp://localhost:4842"}

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"plc-logic"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t $DOCKER_BUILD_TAG