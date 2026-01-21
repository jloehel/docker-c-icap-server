#!/bin/bash

# Healthcheck script for c-icap with squidclamav
# Uses c-icap-client to send an OPTIONS request to verify the server is responding

set -e

CICAP_HOST="${CICAP_HEALTHCHECK_HOST:-localhost}"
CICAP_PORT="${CICAP_PORT:-1344}"
CICAP_SERVICE="${CICAP_HEALTHCHECK_SERVICE:-squidclamav}"

# Use c-icap-client for healthcheck
# -i: ICAP server name
# -p: Server port
# -s: Service name
# (no -f means just send OPTIONS request)
if c-icap-client -i "${CICAP_HOST}" -p "${CICAP_PORT}" -s "${CICAP_SERVICE}" > /dev/null 2>&1; then
    exit 0
else
    exit 1
fi
