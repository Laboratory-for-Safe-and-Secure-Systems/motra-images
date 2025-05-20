#!/usr/bin/env bash

# treat undefined variables as an error
set -u

# start the server
cd /usr/src/app  || exit
./KRITIS3M
