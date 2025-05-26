#!/bin/bash

if [ -n "$1" ]; then
    NETWORK_NAME=$1

    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
        echo "Network ${NETWORK_NAME} does not exist. Creating it..."
        docker network create "${NETWORK_NAME}"
    else
        echo "Network ${NETWORK_NAME} already exists."
    fi
fi

