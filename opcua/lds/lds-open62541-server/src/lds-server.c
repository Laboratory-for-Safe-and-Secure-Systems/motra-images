#include <argp.h>
#include <open62541/common.h>
#include <open62541/plugin/log.h>
#include <open62541/types.h>
#include <open62541/util.h>
#include <signal.h>
#include <stdlib.h>
#include "utils.h"
#include <assert.h>

// #include <open62541/plugin/create_certificate.h>
#include <open62541/plugin/log_stdout.h>
#include <open62541/server.h>
#include <open62541/server_config_default.h>

#define MAX_SIZE_TRUSTLIST 10
#define MAX_SIZE_ISSUERLIST 10

static size_t trustListSize = 0;
static size_t issuerListSize = 0;

/*
 * Signal handling
 */
static volatile UA_Boolean running = true;

static void stopHandler(int signum)
{
    running = false;
}

/*
 * Argparser
 */
const char* argp_program_version = "plc-server 0.1";
const char* argp_program_bug_address = "las3@oth-regensburg.de";
static char doc[] = "OPC UA Server -- providing encrypted access to database contents";
static char args_doc[] = "";
static struct argp_option options[] = {
    {"encrypt",     'e', 0,      0, "Enable encryption" },
    {"certificate", 'c', "FILE", 0, "Server certificate" },
    {"key",         'k', "FILE", 0, "Private key" },
    {"trustlist",   't', "FILE", 0, "Trust list" },
    {"issuerlist",  'i', "FILE", 0, "Issuer list" },
    { 0 }
};

struct arguments
{
    char *dbname;
    char *cert;
    char *private;
    char *trustlist[MAX_SIZE_TRUSTLIST];
    char *issuerlist[MAX_SIZE_ISSUERLIST];
    int encrypt;
};

static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
    struct arguments *arguments = state->input;

    switch(key)
    {
        case 'd':
        {
            arguments->dbname = arg;
            break;
        }
        case 'c':
        {
            arguments->cert = arg;
            break;
        }
        case 'k':
        {
            arguments->private = arg;
            break;
        }
        case 'e':
        {
            arguments->encrypt = 1;
            break;
        }
        case 't':
        {
            if( trustListSize < MAX_SIZE_TRUSTLIST )
            {
                arguments->trustlist[trustListSize++] = arg;
            }
            else
            {
                UA_LOG_INFO(UA_Log_Stdout, UA_LOGCATEGORY_USERLAND,
                            "Max number of trustlist entries reached. Ignoring %s",
                            arg);
            }
            break;
        }
        case 'i':
        {
            if( issuerListSize < MAX_SIZE_ISSUERLIST )
            {
                arguments->issuerlist[issuerListSize++] = arg;
            }
            else
            {
                UA_LOG_INFO(UA_Log_Stdout, UA_LOGCATEGORY_USERLAND,
                            "Max number of issuerlist entries reached. Ignoring %s",
                            arg);
            }
            break;
        }
        default:
        {
            return ARGP_ERR_UNKNOWN;
        }
    }
    return 0;
}

static struct argp argp = { options, parse_opt, args_doc, doc };

/*
 * Structure needed to pass objects to callbacks
 */
typedef struct {
    UA_NodeId fillPctNodeIdent;
    UA_NodeId valvePosNodeIdent;
    UA_NodeId thresholdNodeIdent;
} CallbackContext;

int main(int argc, char *argv[])
{
  // register the interrupt handlers, alternative is to run tiny inside docker 
    signal(SIGINT, stopHandler);
    signal(SIGTERM, stopHandler);

    UA_LOG_INFO(UA_Log_Stdout, UA_LOGCATEGORY_USERLAND,
        "Starting the LDS C Server");
    /*
     * Default arguments
     */
    struct arguments arguments = {
        .cert = "/pki/cert.der",
        .private = "/pki/key.der",
        .trustlist = {""},
        .issuerlist = {""},
        .encrypt = false,
    };
    argp_parse(&argp, argc, argv, 0, 0, &arguments);


    UA_StatusCode retval = UA_STATUSCODE_GOOD;
    UA_ByteString cert = UA_BYTESTRING_NULL;
    UA_ByteString privateKey = UA_BYTESTRING_NULL;


    // load some default config (we might need to check/parse this in the future?)
    static UA_ServerConfig config;
    memset(&config, 0, sizeof(UA_ServerConfig));
    UA_ServerConfig_setDefault(&config);
    // Minimum is 8192
    // config.tcpBufSize = 1 << 13;
    // config.tcpMaxMsgSize = 1 << 13;
    // config.maxSecureChannels = 5;
    // config.maxSessions = 5;
    // config.serverUrls = UA_String_fromChars("opc.tcp://0.0.0.0:4840");
    // config.serverUrlsSize = 1;

    // This is an LDS server only. Set the application type to DISCOVERYSERVER.
    // NOTE: This will cause UaExpert to not show this instance in the server list.
    // See also: https://forum.unified-automation.com/topic1987.html
    config.applicationDescription.applicationType = UA_APPLICATIONTYPE_DISCOVERYSERVER;
    UA_String_clear(&config.applicationDescription.applicationUri);
    config.applicationDescription.applicationUri =
            UA_String_fromChars("urn:open62541.example.local_discovery_server");

    // Enable the mDNS announce and response functionality
    config.mdnsEnabled = true;
    config.mdnsConfig.mdnsServerName = UA_String_fromChars("LDS");

    // E.g. here we only set LDS, and you will not see it in UaExpert
    config.mdnsConfig.serverCapabilitiesSize = 1;
    UA_String *caps = (UA_String *) UA_Array_new(1, &UA_TYPES[UA_TYPES_STRING]);
    caps[0] = UA_String_fromChars("LDS");
    config.mdnsConfig.serverCapabilities = caps;


    /*
     * Create and setup server
     */
    UA_Server *server = UA_Server_newWithConfig(&config);
    assert(server);
    if (!server) 
    {
        UA_LOG_INFO(UA_Log_Stdout, UA_LOGCATEGORY_USERLAND,
                    "Failed to instantiate the main server instance");
        retval = UA_STATUSCODE_BADUNEXPECTEDERROR;
        goto cleanup;
    }

    // run the configured LDS
    if(!running) goto cleanup_server;
    retval = UA_Server_run(server, &running);

cleanup_server:
    UA_Server_delete(server);

cleanup:
    return retval = UA_STATUSCODE_GOOD ? EXIT_SUCCESS : EXIT_FAILURE;
}
