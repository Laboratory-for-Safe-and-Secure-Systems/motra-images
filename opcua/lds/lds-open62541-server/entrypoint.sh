#!/usr/bin/env bash

# this is required for the github runner to not mix paths
cd /usr/src/app  || exit

# construct optional args for the python server
args=()
if [ -n "$1" ]; then
    args+=(-f "$1")
fi

# start the server 
opcua-lds-c
