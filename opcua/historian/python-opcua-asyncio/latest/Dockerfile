FROM python:3.11.12-slim-bookworm

# set environment variables here with 'ENV VAR=value'
# this allows dynamic customization of container behavior

# address of the PLC OPC UA server
ENV SERVER_URI=

# update index and install packages if necessary with
RUN apt-get update && apt-get install -y \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Install needed Python packages
RUN pip install \
    asyncua \
    aiosqlite

# Mount volume
VOLUME /database

# Copy app files
COPY /app /app

# startup is controlled by this script which depends on environment variables
COPY /startup.sh /

# will be executed on startup
ENTRYPOINT [ "usr/bin/env" ]

# arguments passed to entrypoint, ensures that environment variables are set
CMD [ "/bin/sh", "/startup.sh" ]
