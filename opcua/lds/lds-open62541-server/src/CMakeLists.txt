cmake_minimum_required(VERSION 3.22)

# Set the project name and version
set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Perform a Release build")
project(opc-c-server VERSION 1.0 LANGUAGES  C)

# Specify C++ standard or C standard if needed
set(CMAKE_C_STANDARD 99)
# set(CMAKE_CXX_STANDARD 14)

# generate output for debugger and intellisense
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


# configure open62541 before loading and parsing the library
set(UA_ENABLE_ENCRYPTION "OPENSSL" CACHE STRING "Use OpenSSL for encryption backend")
set (UA_NAMESPACE_ZERO "FULL" CACHE STRING "Use full namespace 0")
set(UA_LOGLEVEL 100 CACHE STRING "Log everything")
option(UA_ENABLE_DA  ""  OFF)
option(UA_ENABLE_PUBSUB ""  OFF)
option(UA_ENABLE_PUBSUB_INFORMATIONMODEL ""  OFF)
option(UA_ENABLE_METHODCALLS ""  ON)
option(UA_ENABLE_DATATYPES_ALL ""  ON)
option(UA_DEBUG ""  ON)
# build with LDS support enabled
option(UA_ENABLE_DISCOVERY "" ON)
option(UA_ENABLE_GDS_PUSHMANAGEMENT "" OFF)
set(UA_ENABLE_DISCOVERY_MULTICAST "ON" CACHE STRING "Build with local mDNS support")



# Examples are built standalone. Find installed open62541
include_directories("${PROJECT_SOURCE_DIR}/open62541")
add_subdirectory (open62541)


# for testing: 
if(NOT CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    # needed or cmake doesn't recognize dependencies of generated files
    set(PROJECT_BINARY_DIR ${CMAKE_BINARY_DIR})
endif()

add_executable(opcua-lds-c
                lds-server.c
                utils.c
                )


# Link the necessary libraries
target_link_libraries(opcua-lds-c
    open62541::open62541        # OPC UA library
    ssl                         # OpenSSL SSL library
    crypto                      # OpenSSL crypto library
    # KRITIS3M::KRITIS3M
)

# Specify include directories if needed (e.g., for open62541)
include_directories(${PROJECT_SOURCE_DIR}/include)

# installation configuration
set(CMAKE_INSTALL_PREFIX "/usr/local")
install(TARGETS opcua-lds-c DESTINATION bin)
include(GNUInstallDirs)