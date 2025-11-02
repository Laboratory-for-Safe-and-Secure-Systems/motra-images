#! /bin/bash

set -e pipefail

# update/rebuild the model compiler just in case
./docker-build.sh

# list of models to generate 
MODEL_FILES=("EmptyModel" "FullSystemModel" "PLCModel" "TankModel" "ValveModel" )
NODESET_CONTEXT=${NODESET_CONTEXT:-$(realpath ../../../meta/demo-nodeset2/)} 

echo "Processing files from array:"
for filename in "${MODEL_FILES[@]}"; do

    echo ""
    echo "  Processing: $filename"
    export ACTION_MODEL_ABSPATH="$(realpath ../../..)/meta/demo-models/${filename}.xml"
    ./docker-run.sh
    MODEL_NAME="${filename%Model}"
    mv output/KRITIS3M.Reference.NodeSet2.xml                ${NODESET_CONTEXT}/${MODEL_NAME}.NodeSet2.xml
    mv output/KRITIS3M.Reference.PredefinedNodes.uanodes     ${NODESET_CONTEXT}/${MODEL_NAME}.PredefinedNodes.uanodes
    echo ""
    echo "##############################################################################################################"
done
