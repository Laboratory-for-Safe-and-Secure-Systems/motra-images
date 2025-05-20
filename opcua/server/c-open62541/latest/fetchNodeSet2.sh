#!/bin/bash

set -u

# we remove the optional KRITIS3M and the trailer from the name 
# also we need to output the artifact name at this stage for the reusable action output
NODESET_ARTIFACT_TARGET=$(echo "$ACTION_NODESET_NAME" | sed -E 's/\..*//')
echo "artifact-name=${NODESET_ARTIFACT_TARGET}-c-glue" >> $GITHUB_OUTPUT

# check the provided root, if we have a valid file
if [[ -n "$ACTION_CUSTOM_MODEL_PATH" ]]; then
  for FILE in ${ACTION_CUSTOM_MODEL_PATH}/*; do
      if [[ -f "$FILE" ]] && [[ "$FILE" =~ \.NodeSet2\.xml$ ]] then
        echo "File $FILE matches. Including in build..."
          FILENAME=$(basename "$FILE")
          echo "nodeset2=${FILENAME}" >> $GITHUB_OUTPUT
          exit 0
      else
        echo "File $FILE does not match."
      fi
  done
fi

# no file found, stop!
exit 1;