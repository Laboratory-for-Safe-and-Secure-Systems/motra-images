#!/bin/sh

# treat undefined variables as an error
set -u

# if SERVER_URI is set, then use it instead
server_uri_opt=""
if [ -n "$SERVER_URI" ]; then
    server_uri_opt="--suri="
fi

# if no ENV is set, the binary is started with defaults
# start the app
python3 /app/app.py "${server_uri_opt}${SERVER_URI}"
