#!/usr/bin/env bash

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
NODESET_CONTEXT=${NODESET_CONTEXT:-$(realpath ../../../../meta/demo-nodeset2/)} 
COMPANIONSPEC_CONTEXT=${COMPANIONSPEC_CONTEXT:-$(realpath ../../../../meta/companion-specifications/)} 

NODESET_MODEL=${NODESET_MODEL:-"FullSystem.NodeSet2.xml"} 
OPEN62541_VERSION=${OPEN62541_VERSION:-"v1.4.11"} 
UA_LOGLEVEL=${UA_LOGLEVEL:-"600"}
UA_DEBUG=${UA_DEBUG:-"OFF"}
# CUSTOM_TARGET=${CUSTOM_TARGET:-"--target development"}
CUSTOM_TARGET=${CUSTOM_TARGET:-""}

docker build \
    --build-context     container_context=$CONTAINER_CONTEXT \
    --build-context     nodeset_context=$NODESET_CONTEXT \
    --build-context     companion_context=$COMPANIONSPEC_CONTEXT \
    --build-arg         OPEN62541_VERSION=$OPEN62541_VERSION \
    --build-arg         NODESET_MODEL=$NODESET_MODEL \
    --build-arg         UA_LOGLEVEL=$UA_LOGLEVEL \
    --build-arg         UA_DEBUG=$UA_DEBUG \
    . \
    $CUSTOM_TARGET \
    -t c-server 