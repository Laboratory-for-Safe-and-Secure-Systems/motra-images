## Usage with Github actions

The github action will build a local c server and precompile a provided model into the docker container at buildtime. This image is fixed once compiled. The custom model needs to be supplied to the code generator as an absolute path, when building the sources of the container. Once the generator has built all required model files, the sources are built and linked inside the development stage. 

```
  - name: Run local action against OPC Service
    uses: ./privateActions/c-server/
    id: opc-test
    with:
        model-path: '${{ github.workspace }}/model'
        service-network: '${{ job.container.network }}' 
        default-opc-port: '4840'
```

Important: `${{ job.container.network }}` will only work correctly if a service container is in use. Otherwise this parameter is empty and will be ignored.

## Usage without Github actions

Build the docker container and copy the model files into the created image.
The default build can be started using the build script for docker. 

```bash
./docker-build.sh
```
The configuration of available parameters can be done by exporting/changing the default environment pre build. 
Available parameters: 

```bash
# Source file contexts for Docker, can be used to customize models and additional OPC specifications
export CONTAINER_CONTEXT=$(realpath .)
export NODESET_CONTEXT=$(realpath ../../meta/demo-nodeset2/)
export COMPANIONSPEC_CONTEXT=$(realpath ../../meta/companion-specifications/) 
``` 

```bash
# build configuration for the image
export NODESET_MODEL="FullSystem.NodeSet2.xml" 
export OPEN62541_VERSION="v1.4.11" 
export UA_LOGLEVEL="100"
export UA_DEBUG="OFF"
```


Start the default container to run a local c server with exposed ports on localhost/0.0.0.0:4840 (default) 

```bash
./docker-run.sh
```

Alternatively the provided paths can be customized and fixed as seen in the example above