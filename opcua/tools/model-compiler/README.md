## Usage

The module model-compiler will generate and validate OPC UA model definitions provided to the generating 
docker container. 

System dependencies and the model compiler will be installed system wide in /usr/local inside the container. Any other dependencies or tools are places inside the /app folder.
The file structure inside the container looks like this:

```
docker system root /
├── usr/local/
│           ├── Opc.Ua.ModelCompiler
│           └── dependencies
├── model
│   ├── input       >>  files for generation
│   ├── output      >>  generated files/mounted to host
│   └── schema      >>  validation files
└── app/
    └── entrypoint.sh
```

When starting the container all required files for generation/validation will be placed inside /model: 

```
├── model/
│   ├── input 
│   │   └── ReferenceModel.xml
│   ├── schemas
│   │   └── <Schemas>.xsd
│   └── output
│       └── Generated files ...
└── app/
    └── entrypoint.sh
```
The files referenced inside /model/input will be used for code and nodeset generation.
The files inside /model/schemas can be used with xmllint to check the files during generation for errors.
The output can be used to mount a custom location into the container to generate code into. 

Build configuration is done by passing a custom setup to the environment: 

```bash
export CONTAINER_CONTEXT=$(realpath .)
export SCHEMA_CONTEXT=$(realpath ../../../meta/schemata/)
export UA_COMPILER_GIT_REF="master"
```

### Usage with Github actions

When using github actions, this composite action can be used to build a docker container and generate NodeSet2.xml files, using a opc compatible model file in XML format.
The compiler needs a valid id assigned, to generate outputs and upload artifacts. 
After generation the produced data can be used by subsequent jobs.

```
- name: Build the Model Compiler and Generate the default set
  uses: ./opcua/tools/model-compiler/
  id: model-compiler
  with:
    model-file: '${{ matrix.models }}'
    action-workspace: '${{ github.workspace }}' 
    model-location: '${{ github.workspace }}/modelFiles' 
```


### Usage without Github actions

This builds the docker container and mounts the model files into the created image.
After execution the corresponding files should  be created inside the output folder.
Alternatively if the output location is omitted, the container can be used for debugging or online generation. The output folder is used to generate a bunch of files for further use downstream.

```bash
./docker-build.sh 
```

When running the container, the image needs three inputs for generating the required files: 

1. the absolute path to the model file (stored in $ACTION_MODEL_ABSPATH)
2. (defaults to ./output) the workspace folder to output the files ($ACTION_OUTPUT_LOCATION)
3. UID and GID to fix any possible permission issues (these are queried during generation, but can be overridden)

Using the provided run script to generate the output files (Code and NodeSets) inside the current working directory: 

```bash
export ACTION_MODEL_ABSPATH="$(realpath ../../..)/meta/demo-models/ValveModel.xml"
./docker-run.sh
```

Alternatively the provided paths can be customized and fixed as seen in the example above