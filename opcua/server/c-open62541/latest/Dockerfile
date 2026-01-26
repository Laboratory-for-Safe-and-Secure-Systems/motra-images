FROM debian:bookworm-slim AS base


# update index and install packages if necessary with
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssl \
    libssl-dev 

FROM base AS development
WORKDIR /development/src/

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y \
    ninja-build \
    build-essential \
    git \
    wget \
    gdb \
    cmake-curses-gui \
    libmbedtls-dev \
    check libsubunit-dev \
    libpcap-dev \
    python3-sphinx graphviz \
    python3-sphinx-rtd-theme \
    python3 \
    netcat-openbsd \
    cmake 
    # wget https://github.com/Kitware/CMake/releases/download/v3.31.7/cmake-3.31.7-linux-aarch64.sh  && \
    # chmod +x cmake-3.31.7-linux-aarch64.sh && \
    # ./cmake-3.31.7-linux-aarch64.sh --prefix=/usr --exclude-subdir --skip-licence 
    # this recent cmake version fixes issues with VS Code to debug the cmake files
    # older versions of cmake dont support the debug interface for the extension
    # this wont work on a x86 type runner, this needs to be customizes

# we clone open62541 separately to include the tools (open62541/tools) inside the build  
# we do NOT configure project specific settings inside here, all configuration is
# done in the wrapper CMakeLists.txt for open62541
# also init all submodules to refer to the external NS0 companion spec files.
# custom files would need to be managed outside of the submodules if needed
ARG OPEN62541_VERSION="v1.4.11"
RUN git clone --depth 1 \
    --branch $OPEN62541_VERSION https://github.com/open62541/open62541.git && \
    cd open62541 && git submodule update --init --recursive 

# collect the models, sources and schemas to build the server
ARG NODESET_MODEL="FullSystem.NodeSet2.xml"
COPY --from=nodeset_context         $NODESET_MODEL      /development/src/nodesets/Default.NodeSet2.xml
COPY --from=companion_context       *                   /development/src/companion_spec/
COPY --from=container_context       src/*.c src/*.h     /development/src/
COPY --from=container_context       src/CMakeLists.txt  /development/src/CMakeLists.txt

ARG UA_LOGLEVEL=400
ARG UA_DEBUG="OFF"
RUN cd /development/src && \
    mkdir build && cd build && \
    cmake .. -G Ninja -DUA_DEBUG=${UA_DEBUG} -DUA_LOGLEVEL=${UA_LOGLEVEL} && \
    cmake --build . --target install --config Release && \
    ldconfig /usr/local/bin

FROM base AS runtime

# get the new libs for open62541
COPY --from=development         /usr/local/bin  /usr/local/bin
COPY --from=development         /usr/local/lib  /usr/local/lib

# startup is controlled by this script which depends on environment variables
COPY --from=container_context   entrypoint.sh   /usr/src/app/entrypoint.sh
COPY --from=container_context   entrypoint.sh   /entrypoint.sh

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "./entrypoint.sh" ] 
