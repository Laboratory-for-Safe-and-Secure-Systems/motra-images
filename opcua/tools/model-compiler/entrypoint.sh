#!/bin/bash
# currently we need to build the final docker container and the required outputs to extend the pipeline
# once the interface to the docker container is done, we can generate output and make the artifacts from the model compiler available for further tests

show_help() {
    echo "Usage: $0 -s <script> -f <file1> [-f <file2> ...] [-h]"
    echo
    echo "  -f <file>       The file(s) to validate. You can specify multiple -f options."
    echo "  -v <version>    The OPC standard reference version to use for generating the output files (v103,v104,v105)."
    echo "  -h              Show this help message."
    exit 0
}

# Check dependencies

if command -v xmllint &> /dev/null; then
    echo "<xmllint> is installed."
else
    echo "<xmllint> is NOT installed or not in PATH."
    exit 1
fi

if command -v Opc.Ua.ModelCompiler &> /dev/null; then
    echo "<Opc.Ua.ModelCompiler> is installed."
else
    echo "<Opc.Ua.ModelCompiler> is NOT installed or not in PATH."
    exit 1
fi


# define the basic file/folder structure

# Define the default folder where INPUT_MODEL should be located
# Keep the output within the /model folder, since we only check if this exists
# typically we want to mount external INPUT_MODEL into the model folders before generating any code or validation steps

TOP_LEVEL_LOCATION=${TOP_LEVEL_LOCATION:-"/model"}          # top level path to the configuration scripts and parsers inside docker 
INPUT_FOLDER=${INPUT_FOLDER:-"input"}               # rel. folder where the input INPUT_MODEL will be mounted/put
OUTPUT_FOLDER=${OUTPUT_FOLDER:-"output"}            # rel. folder where INPUT_MODEL are generated into
SCHEMA_FOLDER=${SCHEMA_FOLDER:-"schemas"}           # rel. folder where schema files for linting are stored

# absolute paths to the different directories:
INFOLDER_LOCATION="$TOP_LEVEL_LOCATION/$INPUT_FOLDER"
SCHEMA_LOCATION="$TOP_LEVEL_LOCATION/$SCHEMA_FOLDER"
OUTFOLDER_LOCATION="$TOP_LEVEL_LOCATION/$OUTPUT_FOLDER"

# inputs for getopts
INPUT_MODEL=()
OPC_STANDARD_VERSION=${OPC_STANDARD_VERSION:-"v104"}

# get the current date, in case we need to generate a model definition
DATE=$(date +"%Y-%m-%d")
echo "Date: $DATE"

# Argument parsing using getopts
while getopts ":f:v:h" opt; do
    case $opt in
        f)
            INPUT_MODEL+=("$OPTARG")  # Add the file to the array, we only parse one and fail any other
            ;;
        v)
            OPC_STANDARD_VERSION=("$OPTARG")
            ;;
        h)
            show_help
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            show_help
            ;;
    esac
done

# Check if the INPUT_MODEL array is empty
if [ ! ${#INPUT_MODEL[@]} -eq 1 ]; then
    echo "Error: More or less than one model files specified for validation."
    echo "Error: Provide exactly one file for validation/generation"
    exit 1
fi

# check if the provided model version is va
case $OPC_STANDARD_VERSION in
    v103|v104|v105)
        echo "Valid opc node set version: $OPC_STANDARD_VERSION";;
    *)
        echo "Invalid flag for opc model version"
        echo "Valid flags are: v103|v104|v105"
        ;;
esac

# check if the directories are set up correctly
if [[ -d "$TOP_LEVEL_LOCATION" ]]; then
    echo "Top level directory for generation found: $TOP_LEVEL_LOCATION"
else
    echo "Error: Top level directory $TOP_LEVEL_LOCATION does not exist."
    exit 1
fi

# these should be provided by docker mounts
# Input files are mandatory for generation
if [[ -d "$INFOLDER_LOCATION" ]]; then
    echo "Input directory: $INFOLDER_LOCATION"
else
    echo "Error: Input directory does not exist."
    exit 1
fi

# these can be mounted into the container optionally
# we can copy those into the release build, since the default schemas wont change
# this needs to fail, bc we are missing required schemas if configuration went bad
if [[ -d "$SCHEMA_LOCATION" ]]; then
    echo "Schema directory: $SCHEMA_LOCATION"
else
    echo "Error: Schema directory does not exist."
    exit 1
fi

# this we need to create, check if anything fails
# this can be a mounted target, then we skip it
mkdir -p "$OUTFOLDER_LOCATION"
if [[ -d "$OUTFOLDER_LOCATION" ]]; then
    echo "Output directory: $OUTFOLDER_LOCATION"
else
    echo "Error: Output directory does not exist."
    exit 1
fi


# generate the initial set of files from the first run
# this initial step will parse the provided model and generate nodesets + code snippets using model compiler 
# Get the model file for parsing
FILE="${INPUT_MODEL[0]}"
INFILE_ABSPATH="$TOP_LEVEL_LOCATION/$INPUT_FOLDER/${INPUT_MODEL[0]}"

echo ""

# Check if a given file exists
if [[ -f "$INFILE_ABSPATH" ]]; then

    echo "\$ xmllint -noout ${INFILE_ABSPATH}"
    xmllint -noout ${INFILE_ABSPATH}

    echo "\$ xmllint --noout --schema /model/schemas/Opc.Ua.ModelDesign.xsd ${INFILE_ABSPATH}"
    xmllint --noout --schema /model/schemas/Opc.Ua.ModelDesign.xsd ${INFILE_ABSPATH}

    echo ""

    # Create a new NodeSet2.xml + additional Sources   
    # NodeConf will be the output file generated from this step
    # we can override the NodeId configuration, id we update this file
    # and then pass it into the build container for another run
    echo "\$ Opc.Ua.ModelCompiler compile -d2 $INFILE_ABSPATH -cg $OUTFOLDER_LOCATION/NodeConf.csv -o2 $OUTFOLDER_LOCATION -version $OPC_STANDARD_VERSION -pd $DATE -exclude Draft"
    Opc.Ua.ModelCompiler compile -d2 "$INFILE_ABSPATH" -cg "$OUTFOLDER_LOCATION/NodeConf.csv" -o2 "$OUTFOLDER_LOCATION" -version "$OPC_STANDARD_VERSION" -pd $DATE -exclude Draft 
    if [[ $? -eq 0 ]]; then
        echo "Generated default model definitions for $FILE in $OUTFOLDER_LOCATION"
        ls -alch $OUTFOLDER_LOCATION | grep *.xml
    else
        echo "Model generation failed for $FILE"
        exit 1 
    fi
fi


# optional step: generate string ids   
#         # we need to pass in the right arguments, to build the next step.
#         # this wont just work without ordering the parameters 
#         # For reference: the csv file can be used to pass "named parameters" to the code generation process
#         # Normally UA Model Compiler would generate numerical NodeIDs for all Nodes, by adding CSV definitions we can alter the IDs to strings.
#         # Accessing these using C/Cpp: UA_NodeId myStringNode = UA_NODEID_STRING(defaultNodeSetNamespace, "indicator.device.id"); instead of UA_NodeId myStringNode = UA_NODEID_NUMERIC(defaultNodeSetNamespace, 20);
#         # dotnet Opc.Ua.ModelCompiler.dll -d2 "$FILE_PATH" -c "$FILE_PATH" -o2 "$OUTPUT_FOLDER" -version v104 -pd $DATE
#         # todo!

echo ""

# if the userid and groupid are provided override the generated ids
# this is required, because github actions need to be run as root
# if we fix this here, we can just pass the ids in before executing the model compiler
echo "Checking if the current environment has UID and GID configured"
if [ -n "$USER_ID" ] && [ -n "$GROUP_ID" ] && [ $USER_ID -ne 0 ]; then
    echo "Fixing file ownership for the output ${OUTFOLDER_LOCATION} ..."
    chown -R $USER_ID:$GROUP_ID ${OUTFOLDER_LOCATION}

else
    echo "No flags found or root anyway; assuming we are running inside github actions"
    echo "skipping ..." 
fi

# check if the generated file is valid using the provided schema files
# we can check the generated model against the UANodeSet.xsd to find any issues with the generated xml 
# specific versions of the file are derived using the OPC Version flags

echo "" 
echo "\$ xmllint --noout --schema /model/schemas/UANodeSet${OPC_STANDARD_VERSION}.xsd ${OUTFOLDER_LOCATION}/KRITIS3M.Reference.NodeSet2.xml"
xmllint --noout --schema /model/schemas/UANodeSet${OPC_STANDARD_VERSION}.xsd ${OUTFOLDER_LOCATION}/KRITIS3M.Reference.NodeSet2.xml

# done 
exit 0