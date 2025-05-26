// source: https://github.com/node-opcua/node-opcua/issues/1391

import { OPCUAServer, nodesets, SecurityPolicy } from "node-opcua";
import { fileURLToPath } from 'url';
import path from 'path';


async function main() {

    // Fixes for ES Module
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = path.dirname(__filename);
    
    const xmlFiles = [
        nodesets.standard, 
        path.join(__dirname, "./nodesets", "Server.NodeSet2.xml"), 
        // path.join(__dirname, "./companion_spec", "compspec", "Opc.Ua.Di.NodeSet2.xml"),
    ];

    const server = new OPCUAServer({
        port: 4840, 
        resourcePath: "/KRITIS3M/", // Configured Endpoint
        buildInfo: { // this needs more work, might get passed from NodeSet to the Server in the future?
            productName: "Pentesting Server",
            buildNumber: "1.0.0",
            buildDate: new Date(),
        },
        skipOwnNamespace: true,
        nodeset_filename: xmlFiles, 
        securityPolicies: [ SecurityPolicy.None, SecurityPolicy.Basic256Sha256 ],
    });

    await server.initialize();
    await server.start();
    console.log("Started OPC UA Node Server! ");
    console.log("Server is now listening on: ", server.getEndpointUrl());
}

main().catch((error) => {
    console.error("Error: ", error);
});
