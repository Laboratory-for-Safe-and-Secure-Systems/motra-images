#!/usr/bin/env bash

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 

OPEN62541_VERSION=${OPEN62541_VERSION:-"v1.4.11"} 
UA_LOGLEVEL=${UA_LOGLEVEL:-"100"}
UA_DEBUG=${UA_DEBUG:-"ON"}
# CUSTOM_TARGET=${CUSTOM_TARGET:-"--target development"}
CUSTOM_TARGET=${CUSTOM_TARGET:-""}

docker build \
    --build-context     container_context=$CONTAINER_CONTEXT \
    --build-arg         OPEN62541_VERSION=$OPEN62541_VERSION \
    --build-arg         UA_LOGLEVEL=$UA_LOGLEVEL \
    --build-arg         UA_DEBUG=$UA_DEBUG \
    . \
    $CUSTOM_TARGET \
    -t lds-c-server 