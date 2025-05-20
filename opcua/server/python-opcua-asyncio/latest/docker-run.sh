#!/bin/bash

set -e pipefail

CUSTOM_OPC_PORT=${CUSTOM_OPC_PORT:-4840}

# Initialize an empty argument string
DOCKER_ARGS=""
CONTAINER_ARGS=""

# Check if the environment variables are set and append arguments accordingly
if [[ -n "$EXPORT_CONTAINER_PORTS" ]]; then
  DOCKER_ARGS+=" -p ${CUSTOM_OPC_PORT}:4840"
fi

if [[ -n "$ACTION_SERVICE_NETWORK" ]]; then
  DOCKER_ARGS+=" --network $ACTION_SERVICE_NETWORK"
fi

# check for the nodeset (<...>.NodeSet2.xml) file if present and mount it into the container
if [[ -n "$ACTION_MODEL_ABSPATH" ]]; then
  echo "Custom model used for server: $ACTION_MODEL_ABSPATH"
  DOCKER_ARGS+=" -v ${ACTION_MODEL_ABSPATH}:/usr/src/app/Server.NodeSet2.xml"
fi

echo " \$ docker run -d $DOCKER_ARGS python-server $CONTAINER_ARGS "
docker run -d $DOCKER_ARGS python-server $CONTAINER_ARGS

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