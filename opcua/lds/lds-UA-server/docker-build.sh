#!/usr/bin/env bash
# PROFILES: discovery, opcua
# DESCRIPTION: OPC UA Foundation discovery server


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 

UA_LDS_VERSION=${UA_LDS_VERSION:-"master"} 
# UA_LOGLEVEL=${UA_LOGLEVEL:-"100"}
# UA_DEBUG=${UA_DEBUG:-"ON"}
# CUSTOM_TARGET=${CUSTOM_TARGET:-"--target development"}

DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"lds-ua-server"}

docker build \
    --build-context     container_context=$CONTAINER_CONTEXT \
    --build-arg         UA_LDS_VERSION=$UA_LDS_VERSION \
    . \
    $CUSTOM_TARGET \
    -t $DOCKER_BUILD_TAG