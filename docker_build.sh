#!/bin/bash -e

# Default values
ARCH="${ARCH:-amd64}"
OS="${OS:-linux}"

IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION:-c-icap server for content adaptation}"
APP_NAME="${APP_NAME:-c-icap-server}"
APP_USERNAME="${APP_USERNAME:-c-icap}"

# Version handling
# Git tag format: <os_flavor>/<os_version>/<app_version>/<build>
# Example: fedora/43/0.6.3/1
# Docker image version: <os_version>-<app_version>-<build>
# Example: 43-0.6.3-1
if [ -z "${CI_BUILD+x}" ]; then
    # Local build - use defaults or environment variables
    OS_FLAVOR="${OS_FLAVOR:-fedora}"
    OS_VERSION="${OS_VERSION:-43}"
    APP_VERSION="${APP_VERSION:-0.6.3}"
    BUILD_NUMBER="${BUILD_NUMBER:-1}"
    IMAGE_VERSION="${IMAGE_VERSION:-${OS_VERSION}-${APP_VERSION}-${BUILD_NUMBER}}"
else
    # CI build - parse version from git tag if IMAGE_VERSION contains slashes
    # Count slashes to detect tag format (should be 3 slashes = 4 parts)
    SLASH_COUNT=$(echo "$IMAGE_VERSION" | tr -cd '/' | wc -c)
    if [ "$SLASH_COUNT" -eq 3 ] && [ -z "${OS_FLAVOR+x}" ]; then
        OS_FLAVOR="$(echo "$IMAGE_VERSION" | cut -d'/' -f1)"
        OS_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f2)"
        APP_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f3)"
        BUILD_NUMBER="$(echo "$IMAGE_VERSION" | cut -d'/' -f4)"
        # Reconstruct IMAGE_VERSION without OS_FLAVOR prefix
        IMAGE_VERSION="${OS_VERSION}-${APP_VERSION}-${BUILD_NUMBER}"
    else
        # Use environment variables or defaults
        OS_FLAVOR="${OS_FLAVOR:-fedora}"
        OS_VERSION="${OS_VERSION:-43}"
        APP_VERSION="${APP_VERSION:-0.6.3}"
        BUILD_NUMBER="${BUILD_NUMBER:-1}"
        IMAGE_VERSION="${IMAGE_VERSION:-${OS_VERSION}-${APP_VERSION}-${BUILD_NUMBER}}"
    fi
fi

# Docker tag - sanitize for valid docker tag
DOCKER_TAG=$(echo "$IMAGE_VERSION" | tr -sc '[:alnum:].\n\r' '-' | tr '[:upper:]' '[:lower:]' | cut -c 1-127)

# Build tag - local tag without registry prefix
BUILD_TAG="${APP_NAME}:${DOCKER_TAG}"

echo "========================================"
echo "Building Docker Image"
echo "========================================"
echo "ARCH: ${ARCH}"
echo "OS: ${OS}"
echo "OS_FLAVOR: ${OS_FLAVOR}"
echo "OS_VERSION: ${OS_VERSION}"
echo "APP_NAME: ${APP_NAME}"
echo "APP_VERSION: ${APP_VERSION}"
echo "BUILD_NUMBER: ${BUILD_NUMBER}"
echo "IMAGE_VERSION: ${IMAGE_VERSION}"
echo "DOCKER_TAG: ${DOCKER_TAG}"
echo "BUILD_TAG: ${BUILD_TAG}"
echo "========================================"

docker build \
    --build-arg ARCH="${ARCH}" \
    --build-arg OS_FLAVOR="${OS_FLAVOR}" \
    --build-arg OS_VERSION="${OS_VERSION}" \
    --build-arg IMAGE_VERSION="${IMAGE_VERSION}" \
    --build-arg IMAGE_DESCRIPTION="${IMAGE_DESCRIPTION}" \
    --build-arg APP_NAME="${APP_NAME}" \
    --build-arg APP_VERSION="${APP_VERSION}" \
    --build-arg APP_USERNAME="${APP_USERNAME}" \
    -t "${BUILD_TAG}" \
    -f Dockerfile .

echo "========================================"
echo "Build complete: ${BUILD_TAG}"
echo "========================================"
