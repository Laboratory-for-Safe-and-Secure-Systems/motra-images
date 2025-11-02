#!/usr/bin/env bash

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
NODESET_CONTEXT=${NODESET_CONTEXT:-$(realpath ../../../../meta/demo-nodeset2/)} 
COMPANIONSPEC_CONTEXT=${COMPANIONSPEC_CONTEXT:-$(realpath ../../../../meta/companion-specifications/)} 
CONFIGURATION_CONTEXT=${CONFIGURATION_CONTEXT:-$(realpath ../../../../meta/server-configuration/)} 

NODESET_MODEL=${NODESET_MODEL:-"FullSystem.PredefinedNodes.uanodes"} 

docker build \
    --build-context     container_context=$CONTAINER_CONTEXT \
    --build-context     nodeset_context=$NODESET_CONTEXT \
    --build-context     companion_context=$COMPANIONSPEC_CONTEXT \
    --build-context     configuration_context=$CONFIGURATION_CONTEXT \
    --build-arg         NODESET_MODEL=$NODESET_MODEL \
    . \
    -t dotnet-server