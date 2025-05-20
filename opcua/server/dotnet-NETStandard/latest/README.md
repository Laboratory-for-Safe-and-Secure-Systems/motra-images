## Usage with Github actions

The github action will build a local .NET server and load a provided model into the docker container at runtime.
INFO: the dotnet server requires a .uanodes file for loading the address space into memory.

```
  - name: Run local action against OPC Service
    uses: ./privateActions/dotnet-server/
    id: opc-test
    with:
        model-path: '${{ github.workspace }}/model'
        service-network: '${{ job.container.network }}' 
        default-opc-port: '4840'
```

Important: `${{ job.container.network }}` will only work correctly if a service container is in use. Otherwise this parameter is empty and will be ignored.

## Usage without Github actions

Build the docker container and mount the model files into the created image.
The default build can be started using the provided docker build script.

```bash
./docker-build.sh
```
Customization of the generic server is done with the environment options:

```bash
export CONTAINER_CONTEXT=$(realpath .) 
export NODESET_CONTEXT=$(realpath ../../meta/demo-nodeset2/) 
export COMPANIONSPEC_CONTEXT=$(realpath ../../meta/companion-specifications/)
export CONFIGURATION_CONTEXT=$(realpath ../../meta/server-configuration/s
export NODESET_MODEL="FullSystem.PredefinedNodes.uanodes"
```

Start the default container to run a local .NET server with exposed ports on localhost/0.0.0.0:4840 

```bash
export ACTION_MODEL_ABSPATH="$(realpath ../../meta/demo-nodeset2/)/FullSystem.PredefinedNodes.uanodes"
export CUSTOM_OPC_PORT=4840
./docker-run.sh
```

Alternatively the provided paths can be customized and fixed as seen in the example above