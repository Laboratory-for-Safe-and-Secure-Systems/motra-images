#!/usr/bin/env bash
# PROFILES: remote, it
# DESCRIPTION: Opensshd default image 


# configure local contexts
CONTAINER_CONTEXT=${CONTAINER_CONTEXT:-$(realpath .)} 
USERNAME=${USERNAME:-"milka"}
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
USER_PASSWD=${USER_PASSWD:-"ninja"}

docker build \
    --build-context container_context=$CONTAINER_CONTEXT \
    . \
    -t opensshd