FROM node:bookworm-slim

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssl \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy app files
ARG NODESET_MODEL="FullSystem.NodeSet2.xml"
WORKDIR /usr/src/app
COPY --from=container_context   src/*           /usr/src/app/
COPY --from=container_context   entrypoint.sh   entrypoint.sh
COPY --from=nodeset_context     $NODESET_MODEL  /usr/src/app/nodesets/Server.NodeSet2.xml
COPY --from=companion_context   *               /usr/src/app/companion_spec/

RUN npm install

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "./entrypoint.sh" ]
