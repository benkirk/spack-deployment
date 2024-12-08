#!/bin/bash

# From https://spack.readthedocs.io/en/latest/getting_started.html

# Install the tools neeed for spack

dnf group install "Development Tools"
dnf install curl findutils gcc-gfortran gnupg2 hostname iproute redhat-lsb-core python3 python3-pip python3-setuptools unzip python3-boto3
