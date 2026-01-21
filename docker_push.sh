#!/bin/bash -e

APP_NAME="${APP_NAME:-c-icap-server}"
IMAGE_VERSION="${IMAGE_VERSION:-latest}"

# Registries to push to (space-separated)
REGISTRIES="${REGISTRIES:-ghcr.io/jloehel docker.io/jloehel}"

# Whether to also push :latest tag
PUSH_LATEST="${PUSH_LATEST:-false}"

# Parse components from IMAGE_VERSION if it matches git tag format
# Git tag format: <os_flavor>/<os_version>/<app_version>/<build>
# Docker version format: <os_version>-<app_version>-<build>
SLASH_COUNT=$(echo "$IMAGE_VERSION" | tr -cd '/' | wc -c)
if [ "$SLASH_COUNT" -eq 3 ]; then
    OS_FLAVOR="$(echo "$IMAGE_VERSION" | cut -d'/' -f1)"
    OS_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f2)"
    APP_VERSION="$(echo "$IMAGE_VERSION" | cut -d'/' -f3)"
    BUILD_NUMBER="$(echo "$IMAGE_VERSION" | cut -d'/' -f4)"
    # Construct version without OS_FLAVOR prefix
    DOCKER_TAG="${OS_VERSION}-${APP_VERSION}-${BUILD_NUMBER}"
else
    OS_FLAVOR="${OS_FLAVOR:-fedora}"
    APP_VERSION=""
    # Sanitize IMAGE_VERSION for docker tag
    DOCKER_TAG=$(echo "$IMAGE_VERSION" | tr -sc '[:alnum:].\n\r' '-' | tr '[:upper:]' '[:lower:]' | cut -c 1-127)
fi

# Source tag from build
BUILD_TAG="${APP_NAME}:${DOCKER_TAG}"

echo "========================================"
echo "Pushing Docker Image"
echo "========================================"
echo "BUILD_TAG: ${BUILD_TAG}"
echo "OS_FLAVOR: ${OS_FLAVOR}"
echo "REGISTRIES: ${REGISTRIES}"
echo "PUSH_LATEST: ${PUSH_LATEST}"
echo "========================================"

for REGISTRY in ${REGISTRIES}; do
    # Push with full version tag (e.g., fedora-43-0.6.3-1)
    FULL_TAG="${REGISTRY}/${APP_NAME}:${DOCKER_TAG}"
    echo "Tagging and pushing: ${FULL_TAG}"
    docker tag "${BUILD_TAG}" "${FULL_TAG}"
    docker push "${FULL_TAG}"

    # Push OS-specific latest tag (e.g., fedora-latest)
    OS_LATEST_TAG="${REGISTRY}/${APP_NAME}:${OS_FLAVOR}-latest"
    echo "Tagging and pushing: ${OS_LATEST_TAG}"
    docker tag "${BUILD_TAG}" "${OS_LATEST_TAG}"
    docker push "${OS_LATEST_TAG}"

    # Push app version tag (e.g., 0.6.3-fedora)
    if [ -n "$APP_VERSION" ]; then
        VERSION_TAG="${REGISTRY}/${APP_NAME}:${APP_VERSION}-${OS_FLAVOR}"
        echo "Tagging and pushing: ${VERSION_TAG}"
        docker tag "${BUILD_TAG}" "${VERSION_TAG}"
        docker push "${VERSION_TAG}"
    fi

    # Push global :latest tag only for fedora and if PUSH_LATEST is true
    if [ "${PUSH_LATEST}" = "true" ] && [ "${OS_FLAVOR}" = "fedora" ]; then
        LATEST_TAG="${REGISTRY}/${APP_NAME}:latest"
        echo "Tagging and pushing: ${LATEST_TAG}"
        docker tag "${BUILD_TAG}" "${LATEST_TAG}"
        docker push "${LATEST_TAG}"
    fi
done

echo "========================================"
echo "Push complete"
echo "========================================"
