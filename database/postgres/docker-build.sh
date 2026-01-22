#!/usr/bin/env bash
# PROFILES: database, it
# DESCRIPTION: Postgres database configuration

# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG:-"postgres"}

docker pull $DOCKER_BUILD_TAG