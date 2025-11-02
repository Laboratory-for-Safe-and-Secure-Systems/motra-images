#!/bin/bash

set -e pipefail

OPC_STANDARD_VERSION=${OPC_STANDARD_VERSION:-"v105"}
DEFAULT_USER_ID=$(id -u)
DEFAULT_GROUP_ID=$(id -g)
ACTION_OUTPUT_LOCATION=${ACTION_OUTPUT_LOCATION:-$(realpath .)/output}

# Initialize an empty argument string
DOCKER_ARGS=""
CONTAINER_ARGS=""

# Check if a model is available and mount the model into the container 
if [[ -n "$ACTION_MODEL_ABSPATH" ]]; then
  echo "Model used for generation: $ACTION_MODEL_ABSPATH"
  MODEL_NAME=$(basename $ACTION_MODEL_ABSPATH)
  CONTAINER_ARGS+=" -f $MODEL_NAME"
  DOCKER_ARGS+=" -v ${ACTION_MODEL_ABSPATH}:/model/input/${MODEL_NAME} "
else
  echo "Error: Model file name is mandatory for generation"
  exit 1
fi

# this parameter is optional, as these are copied into the container on build
# we can however override the default schemas from outside
if [[ -n "$ACTION_SCHEMA_LOCATION" ]]; then
  echo "Alternative opc/xml schema files provided: $ACTION_SCHEMA_LOCATION"
  DOCKER_ARGS+=" -v ${ACTION_SCHEMA_LOCATION}:/model/schemas"
fi

# output folder 
# if a path is provided, we create the folder structure and mount it
# this way we can generate the required files inside a host directory
# this defaults to the local-dir/output
if [[ -n $ACTION_OUTPUT_LOCATION ]]; then
  mkdir -p ${ACTION_OUTPUT_LOCATION}
  DOCKER_ARGS+=" -v ${ACTION_OUTPUT_LOCATION}:/model/output"
fi

# provide the OPC UA standard version to the compiler 
# this defaults to v105, since this is most supported rn
if [[ -n "$OPC_STANDARD_VERSION" ]]; then
  CONTAINER_ARGS+=" -v $OPC_STANDARD_VERSION"
fi

# apply a user id to the files/process
# this is intended to run the generation process as a local user or as root
# this is required to fix permission issues when generating for a local user
DOCKER_ARGS+=" -e USER_ID=${DEFAULT_USER_ID}"
DOCKER_ARGS+=" -e GROUP_ID=${DEFAULT_GROUP_ID}"

echo "\$ docker run $DOCKER_ARGS model-compiler $CONTAINER_ARGS "
docker run $DOCKER_ARGS model-compiler $CONTAINER_ARGS
