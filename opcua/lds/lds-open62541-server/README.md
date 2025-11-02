## Usage with Github actions

This image generates a standalone LDS based on the OPEN62541 project.

```
  - name: Run local action against OPC Service
    uses: ./modules/lds-open62541-server
    id: opc-62541-lds
```

Important: `${{ job.container.network }}` will only work correctly if a service container is in use. Otherwise this parameter is empty and will be ignored.

## Usage without Github actions

The default build can be started using the build script for docker. 

```bash
./docker-build.sh
```
The configuration of available parameters can be done by exporting/changing the default environment pre build. 
Available parameters: 

```bash
# Source file contexts for Docker, can be used to customize models and additional OPC specifications
export CONTAINER_CONTEXT=$(realpath .)
``` 

```bash
# build configuration for the image
export OPEN62541_VERSION="v1.4.11" 
export UA_LOGLEVEL="100"
export UA_DEBUG="OFF"
```


Start the default container to run a local lds server with exposed ports on localhost/0.0.0.0:4840 (default) 

```bash
./docker-run.sh
```

Alternatively the provided paths can be customized and fixed as seen in the example above