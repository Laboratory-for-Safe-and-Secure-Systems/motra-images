FROM python:3.11.12-slim-bookworm

# set environment variables here with 'ENV VAR=value'
# this allows dynamic customization of container behavior

# address of the OPC UA server
ENV SERVER_URI=

# Install needed Python packages
RUN pip install asyncua

# Copy app files
COPY --from=container_context app /app

# startup is controlled by this script which depends on environment variables
COPY --from=container_context startup.sh /

# will be executed on startup
ENTRYPOINT [ "usr/bin/env" ]

# arguments passed to entrypoint, ensures that environment variables are set
CMD [ "/bin/sh", "/startup.sh" ]
