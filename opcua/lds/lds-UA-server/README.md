## Usage with Github actions

This will build a local LDS from the UA Foundation for testing.

```
  - name: Run local action against OPC Service
    uses: ./privateActions/lds-UA-server/
    id: opc-lds
    with:
        lds-version: 'master'
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
# build configuration for the image
export UA_LDS_VERSION="master" 
```

Start the default container to run a local c server with exposed ports on localhost/0.0.0.0:4840 (default) 

```bash
./docker-run.sh
```
