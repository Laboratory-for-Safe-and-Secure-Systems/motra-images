#!/bin/sh

# treat undefined variables as an error
set -u

# if LSS_URI is set, then use it instead
lss_uri_opt=""
if [ -n "$LSS_URI" ]; then
    lss_uri_opt="--lss="
fi

# if VS_URI is set, then use it instead
vs_uri_opt=""
if [ -n "$VS_URI" ]; then
    vs_uri_opt="--vs="
fi

# if PS_URI is set, then use it instead
ps_uri_opt=""
if [ -n "$PS_URI" ]; then
    ps_uri_opt="--ps="
fi

# if no ENV is set, the binary is started with defaults
# start the app
python3 /app/app.py "${lss_uri_opt}${LSS_URI}" "${vs_uri_opt}${VS_URI}" "${ps_uri_opt}${PS_URI}" 
