#!/usr/bin/env bash
# PROFILES: tool
# DESCRIPTION: OPC UA Model compiler to rebuild or modify existing data architectures.


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
SCHEMA_CONTEXT=${SCHEMA_CONTEXT:-$(realpath ../../../meta/schemata/)} 

UA_COMPILER_GIT_REF=${UA_COMPILER_GIT_REF:-"master"}

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"model-compiler"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    --build-context schema_context=$SCHEMA_CONTEXT \
    --build-arg     UA_COMPILER_GIT_REF=$UA_COMPILER_GIT_REF \
    . \
    -t $DOCKER_BUILD_TAG