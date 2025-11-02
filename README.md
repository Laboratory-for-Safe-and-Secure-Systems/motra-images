# MOdular Testbed for Researching Attacks (MOTRA) - images

<p align="center">
  <img src=meta/motra.jpeg?raw=true" alt="motra logo" width="350"/>
</p>

MOTRA is a flexible framework for creating testbeds tailored to the user's needs.

Its main features are its modularity and extensibility through packaging testbed components as containerized applications. Docker is the containerization solution of choice. This repository contains the sources for all available images on Dockerhub. There is a [companion](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-setups) repository available which contains ready-to-use testbed setups that uses these images.

## Current State of Module Development

__OPC Servers__ \
[![pkg Release UA Standard dotnet to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-dotnet-UAStandard-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-dotnet-UAStandard-to-GHCR.yaml) \
[![pkg Release NodeJS node-opcua to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-nodejs-node-opcua-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-nodejs-node-opcua-to-GHCR.yaml) \
[![pkg Release Python asyncua to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-python-asyncua-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-python-asyncua-to-GHCR.yaml) \
[![pkg Release open62541 to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-open62541-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-open62541-to-GHCR.yaml)

__LDS Servers__ \
[![pkg Release UA Standard LDS to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-lds-UA-standard-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-lds-UA-standard-to-GHCR.yaml) \
[![pkg Release open62541 LDS to GHCR](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-lds-open62541-to-GHCR.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-lds-open62541-to-GHCR.yaml)

__Simulation and Demo Models__ \
[![OPC UA Model Generation and Verification](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/full-opc-server-model-gen-checks.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/full-opc-server-model-gen-checks.yaml)

__Model Compiler, Source Generator__ \
[![model-compiler Build and pkg Release](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-test-UA-model-compiler.yaml/badge.svg)](https://github.com/Laboratory-for-Safe-and-Secure-Systems/motra-images/actions/workflows/publish-test-UA-model-compiler.yaml)

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project was created to collect sources for testbed components. We needed quickly adaptable and configurable testbeds to perform specific penetration tests against different components and implementations. As we realized, there are few open-source projects available to draw from, so we decided to make ours available to the public and use the community to extend it to any domain they see fit.

## Getting Started

### Prerequisites

The project only requires a working Docker engine. We try to use the latest version for testing our images, but it can work with older versions. Currently, we use:

```bash
docker >= 28.0
```

### Usage

After cloning the repository, you can inspect and modify the sources for creating images. The repository is organized hierarchically, which for now can be depicted as:

```bash
/
  /protocol
    /functionality
      README - contains explanation of packaged functionality
      /protocol-library
        /version
          Dockerfile
          # any other sources needed
```
We also automatically build and upload ready-to-use images to ``ghcr.io/Laboratory-for-Safe-and-Secure-Systems``. To build an image, just change into the directory with the Dockerfile you want to build and execute in a shell
```bash
docker build -t <image-name>:<image-tag> .
```

## Contributing

If you want to contribute images yourself, feel free to open pull requests. Please add a README that briefly explains what the image does and how it can be used. You can reach out to us by opening an issue.

## License

GPLv3 License – see LICENSE for details.

## Current Publications 

Main testbed setup, usage and research directions:
> S. Kraust, P. Heller and J. Mottok, "A Modular and Flexible OPC UA Testbed Prototype for Cybersecurity Research", in proceedings of the Nineteenth International Conference on Emerging Security Information, Systems and Technologies, Barcelona, Spain
ISBN: 978-1-68558-306-4, October 26, 2025 to October 30, 2025.

Design and concept for the testbed components for OPC UA and our custom components: 
> P. Heller, S. Kraust, J. Mottok, "Building Modular OPC UA Testbed Components for Industrial Security Pentesting", in proceedings of 30th International Conference on Applied Electronics 2025, Pilsen, Czech Republic.

The general testbed design and research concepts:
> S. Kraust, P. Heller and J. Mottok, "Concept for Designing an ICS Testbed from a Penetration Testing Perspective," 2025 IEEE European Symposium on Security and Privacy Workshops (EuroS&PW), Venice, Italy, 2025, pp. 561-568, doi: 10.1109/EuroSPW67616.2025.00071.

