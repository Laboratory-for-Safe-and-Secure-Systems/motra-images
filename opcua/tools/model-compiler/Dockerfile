FROM mcr.microsoft.com/dotnet/runtime:9.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# clone and build the ModelCompiler for dotnet
ARG UA_COMPILER_GIT_REF="master"
RUN git clone --depth 1 --branch $UA_COMPILER_GIT_REF https://github.com/OPCFoundation/UA-ModelCompiler.git --recursive 

# this is persistent accross the build layers, also downstream stages inherit this configuration
ENV OPTIONS="-c Release -f net9.0 -p:NoHttps=true -p:Dockerbuild=true -p:CustomTestTarget=net9.0"


# this step is used to build the OPC UA model compiler directly from the .NET sources from github
FROM build AS publish
WORKDIR /src/UA-ModelCompiler/
ENV DOTNET_EnableWriteXorExecute=0
# output the executable and all required .dlls to /app/publish
RUN dotnet build "ModelCompiler.sln" ${OPTIONS} -o /app/publish 

# copy the model compiler into a new instance and generate NodeSet definitions from the OPC data models
FROM base AS final
WORKDIR /app

# add dependency for our validator, this just uses the default xml lib from python to do some basic syntax checks
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y \
    python3 \
    libxml2-utils

# install the built model compiler system wide
# we need the compiler to be available everywhere
COPY --from=publish             /app/publish/*  /usr/local/bin

# install the validators and startup scripts locally
COPY --from=container_context   entrypoint.sh   /app/
COPY --from=schema_context      *               /model/schemas/

ENTRYPOINT [ "/usr/bin/env" , "./entrypoint.sh" ]
# run the build script to check the model files, before compiling them using UA Model Compiler 
CMD [" -h "]