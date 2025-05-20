## Usage with Github actions

The github action will build a local node server and load a provided model into the docker container at runtime.
The parameter for a custom model is a path to a valid folder. 
The startup script will check the folder and tries to find a file ending in NodeSet2.xml and passes the file into the docker container.
If a file is matched, the file is mounted into the container, hiding the default fallback model.

```
  - name: Run local action against OPC Service
    uses: ./privateActions/node-server/
    id: opc-test
    with:
        model-path: '${{ github.workspace }}/model'
        service-network: '${{ job.container.network }}' 
        default-opc-port: '4840'
```

Important: `${{ job.container.network }}` will only work correctly if a service container is in use. Otherwise this parameter is empty and will be ignored.

## Usage without Github actions

Build the docker container and mount the model files into the created image.
The default build can be started using docker build script.

```bash
./docker-build.sh
```
The build configuration is done using the provided environment defaults, which can be changed as needed:

```bash
export CONTAINER_CONTEXT=$(realpath .)
export NODESET_CONTEXT=$(realpath ../../meta/demo-nodeset2/)
export COMPANIONSPEC_CONTEXT=$(realpath ../../meta/companion-specifications/)
```

Start the default container to run a local node server with exposed ports on localhost/0.0.0.0:4840 

```bash
export ACTION_MODEL_ABSPATH="$(realpath ../../meta/demo-nodeset2)/FullSystem.NodeSet2.xml"
export CUSTOM_OPC_PORT=4840
./docker-run.sh
```

Alternatively the provided paths can be customized and fixed as seen in the example above