#!/bin/bash

# stop on error
set -e pipefail

CUSTOM_OPC_PORT=${CUSTOM_OPC_PORT:-4840}
CUSTOM_LDS_PORT=${CUSTOM_LDS_PORT:-5353}

# TODO embedding of metadata would be usefull

# Initialize an empty argument string
DOCKER_ARGS=""
CONTAINER_ARGS=""

# Check if the environment variables are set and append arguments accordingly
if [[ -n "$EXPORT_CONTAINER_PORTS" ]]; then
  DOCKER_ARGS+=" -p ${CUSTOM_OPC_PORT}:4840"
  DOCKER_ARGS+=" -p ${CUSTOM_LDS_PORT}:5353"
fi

if [[ -n "$ACTION_SERVICE_NETWORK" ]]; then
  DOCKER_ARGS+=" --network $ACTION_SERVICE_NETWORK"
fi

DOCKER_ARGS+=" -h testlds "

echo " \$ docker run -d $DOCKER_ARGS lds-c-server $CONTAINER_ARGS "
docker run -d $DOCKER_ARGS lds-c-server $CONTAINER_ARGS

# Output the newly generated Container ID for the calling workflow 
# skip this step if we are running locally 
CONTAINER_ID=$(docker ps -lq)
echo "ID of new Service Container >> cid=$CONTAINER_ID"
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "cid=$CONTAINER_ID" >> "$GITHUB_OUTPUT"
fi

# get the initial logs from container start, if something goes bad
DEFAULT_LOG_WAIT_DELAY=${DEFAULT_LOG_WAIT_DELAY:-3}
sleep $DEFAULT_LOG_WAIT_DELAY
docker logs $CONTAINER_ID