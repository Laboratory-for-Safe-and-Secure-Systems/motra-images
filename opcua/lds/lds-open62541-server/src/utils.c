#include "utils.h"
#include <open62541/config.h>
#include <open62541/server.h>
#include <open62541/types.h>
#include <stdio.h>

// compiled this with GPT
// we can query the existing namespaces, that open62541 stores within the well '
// known node 2255 to get all existing namespace ids.
// these SHOULD be queried, because the ids are allowed to change depending on 
// the server implementatin and how the server side profiles are imported
int getNamespaceIndexByURN(UA_Server *server, const char *targetURN) {
    // Define the NodeId for NamespaceArray: ns=0;i=2255
    UA_NodeId namespaceArrayNodeId = UA_NODEID_NUMERIC(0, 2255);

    // Read the NamespaceArray
    UA_Variant value;
    UA_Variant_init(&value);
    UA_StatusCode retval = UA_Server_readValue(server, namespaceArrayNodeId, &value);

    // Check if the read operation succeeded and the data is an array of strings
    if(retval != UA_STATUSCODE_GOOD || !UA_Variant_hasArrayType(&value, &UA_TYPES[UA_TYPES_STRING])) {
        printf("Failed to read NamespaceArray or incompatible data type.\n");
        UA_Variant_clear(&value);
        return -1;
    }

    // Access and iterate over the NamespaceArray
    UA_String *namespaceArray = (UA_String *) value.data;
    size_t namespaceArraySize = value.arrayLength;
    int namespaceIndex = -1;

    for (size_t i = 0; i < namespaceArraySize; i++) {
        // Compare the namespace entry with the target URN
        if (strncmp((const char*)namespaceArray[i].data, targetURN, namespaceArray[i].length) == 0) {
            namespaceIndex = (int)i;
            printf("Namespace URN '%s' found at index: %d\n", targetURN, namespaceIndex);
            break;
        }
    }

    // Clean up and return the found namespace index
    UA_Variant_clear(&value);       
    return namespaceIndex;
}

UA_ByteString loadFile(const char *const path)
{
    UA_ByteString fileContents = UA_STRING_NULL;

    /* Open the file */
    FILE *fp = fopen(path, "rb");
    if(!fp)
    {
        /*
         * This returns an empty UA_ByteString to check for
         */
        return fileContents;
    }

    /*
     * Get the file length, allocate the data and read
     */
    fseek(fp, 0, SEEK_END);
    fileContents.length = (size_t)ftell(fp);
    fileContents.data = (UA_Byte *)UA_malloc(fileContents.length * sizeof(UA_Byte));
    if(fileContents.data)
    {
        fseek(fp, 0, SEEK_SET);
        size_t read = fread(fileContents.data, sizeof(UA_Byte), fileContents.length, fp);
        if(read != fileContents.length)
        {
            UA_ByteString_clear(&fileContents);
        }
    }
    else
    {
        fileContents.length = 0;
    }
    fclose(fp);
    return fileContents;
}


UA_StatusCode findAttributeNodeId(
    UA_Server *server,
    const UA_NodeId *startNodeIdent,
    const UA_QualifiedName *qName,
    UA_NodeId *attributeNodeId)
{
    UA_RelativePathElement rpe;
    UA_RelativePathElement_init(&rpe);
    rpe.referenceTypeId = UA_NODEID_NUMERIC(0, UA_NS0ID_HASCOMPONENT);
    rpe.isInverse = false;
    rpe.includeSubtypes = false;
    rpe.targetName = *qName;

    UA_BrowsePath bp;
    UA_BrowsePath_init(&bp);
    bp.startingNode = *startNodeIdent;
    bp.relativePath.elementsSize = 1;
    bp.relativePath.elements = &rpe;

    UA_BrowsePathResult bpr = UA_Server_translateBrowsePathToNodeIds(server, &bp);
    if(bpr.statusCode != UA_STATUSCODE_GOOD || bpr.targetsSize < 1)
    {
        return bpr.statusCode;
    }
    *attributeNodeId = bpr.targets[0].targetId.nodeId;

    return UA_STATUSCODE_GOOD;
}