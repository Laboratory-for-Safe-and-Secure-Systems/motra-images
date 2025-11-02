#!/usr/bin/env bash

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
SCHEMA_CONTEXT=${SCHEMA_CONTEXT:-$(realpath ../../../meta/schemata/)} 

UA_COMPILER_GIT_REF=${UA_COMPILER_GIT_REF:-"master"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    --build-context schema_context=$SCHEMA_CONTEXT \
    --build-arg     UA_COMPILER_GIT_REF=$UA_COMPILER_GIT_REF \
    . \
    -t model-compiler 