#!/bin/bash -e

export CI_BUILD=true
export APP_NAME=c-icap-server
export APP_USERNAME=c-icap
export REGISTRIES="ghcr.io/jloehel docker.io/jloehel"
export PUSH_LATEST=true

echo "========================================"
echo "Weekly Build"
echo "========================================"

# Get latest tag for Fedora
# Tag format: <os_flavor>/<os_version>/<app_version>/<build>
FEDORA_TAG=$(git tag -l 'fedora/*' --sort=-v:refname | head -1)

# Build Fedora if tag exists
if [ -n "$FEDORA_TAG" ]; then
    echo "Building Fedora: ${FEDORA_TAG}"
    export IMAGE_VERSION="${FEDORA_TAG}"
    export IMAGE_DESCRIPTION="c-icap-server ${FEDORA_TAG} weekly rebuild"
    ./docker_build.sh
    ./docker_push.sh
fi

echo "========================================"
echo "Weekly Build complete"
echo "========================================"
