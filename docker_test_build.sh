#!/bin/bash -e

export ARCH=amd64
export OS=linux
export OS_FLAVOR=fedora
export OS_VERSION=43
export IMAGE_VERSION=latest
export IMAGE_DESCRIPTION="test c-icap-server build"
export APP_NAME=c-icap-server
export APP_VERSION=0.6.3
export APP_USERNAME=c-icap

./docker_build.sh
