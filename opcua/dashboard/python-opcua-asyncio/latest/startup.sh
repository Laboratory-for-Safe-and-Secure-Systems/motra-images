#!/bin/sh

# treat unset variables as an error
set -u

# if SERVER_URI is set, then use it instead
server_uri_opt=""
if [ ! -z $SERVER_URI ]; then
    server_uri_opt="--suri="
fi

# generate keys for encryption
/pki/gen_kc_pair.sh


# if no ENV is set, the app is started with defaults
# start the application
python3 /app/app.py "${server_uri_opt}${SERVER_URI}"
