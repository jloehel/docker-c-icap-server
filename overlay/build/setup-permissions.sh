#!/bin/bash
# shellcheck shell=bash
# Setup permissions for rootless container

set -eux

# No need to create user here - NSS wrapper creates it on-demand at runtime
# This allows running with arbitrary UIDs (OpenShift compatibility)

# Ensure directories exist
mkdir -p "${CICAP_HOME}" "${CICAP_RUN}" /var/log/c-icap /tmp/c-icap

# Set ownership and permissions
# Group 0 (root) must have write access for arbitrary UID support
chown -R "${APP_UID}:${APP_GID}" \
    "${CICAP_HOME}" \
    "${CICAP_RUN}" \
    /var/log/c-icap \
    /tmp/c-icap \
    /etc/c-icap

chmod -R g+rwX \
    "${CICAP_HOME}" \
    "${CICAP_RUN}" \
    /var/log/c-icap \
    /tmp/c-icap \
    /etc/c-icap

# Scripts must be executable
chmod +x /entrypoint.sh /run.sh /healthcheck.sh
chmod +x /opt/c-icap/generate-config.sh
