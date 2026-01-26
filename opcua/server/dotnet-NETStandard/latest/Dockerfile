FROM mcr.microsoft.com/dotnet/runtime:8.0-jammy AS base

# Install dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssl \
    libssl-dev \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:8.0-jammy AS build
WORKDIR /src

# copy csproj and the project files to the build container to publish
COPY --from=container_context       *       /src/

ENV OPTIONS="-c Release -f net8.0 -p:NoHttps=true -p:Dockerbuild=true -p:CustomTestTarget=net8.0"

FROM build AS publish
ENV DOTNET_EnableWriteXorExecute=0
RUN dotnet publish "KRITIS3M.csproj" ${OPTIONS} -o /app/publish 

FROM base AS final
WORKDIR /usr/src/app

# this needs a fix, we need to pass the downloaded files into the server (and add defaults)
# we need to set up the Server.Config.xml inside the assets path, so we can test locally and 
# using github actions. This way we can also override it selectively using docker mounts
ARG SERVER_CONFIGURATION="KRITIS3M.Server.Config.xml"
ARG NODESET_MODEL="FullSystem.PredefinedNodes.uanodes"
COPY --from=publish                 /app/publish/*              /usr/src/app/
COPY --from=container_context       entrypoint.sh               /usr/src/app/entrypoint.sh
COPY --from=configuration_context   ${SERVER_CONFIGURATION}     assets/KRITIS3M.Server.Config.xml
COPY --from=nodeset_context         ${NODESET_MODEL}            assets/KRITIS3M.Server.NodeSet2.uanodes

ENTRYPOINT [ "/usr/bin/env" ]
CMD [ "./entrypoint.sh" ]
