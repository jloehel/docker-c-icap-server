#!/bin/bash -e

# shellcheck source=/dev/null
. /opt/base/functions

# Set umask to ensure group write permissions on all created files
umask 0002

DAEMON=c-icap
EXEC=$(command -v $DAEMON)
CONFIG_FILE="/etc/c-icap/c-icap.conf"

########################
# Setup environment
########################
setup_env() {
    info "Setting up environment..."

    # Ensure directories exist
    ensure_dir "${CICAP_RUN}"
    ensure_dir "/var/log/c-icap"
    ensure_dir "/tmp/c-icap"
}

########################
# Check if custom config is provided
########################
check_custom_config() {
    if [[ -f "${CICAP_CUSTOM_CONFIG:-}" ]]; then
        info "Using custom configuration from ${CICAP_CUSTOM_CONFIG}"
        cp "${CICAP_CUSTOM_CONFIG}" "${CONFIG_FILE}"
        return 0
    fi

    if [[ -f "/etc/c-icap/c-icap.conf" ]] && [[ -s "/etc/c-icap/c-icap.conf" ]]; then
        # Config exists and is not empty, check if it was mounted
        if [[ "${CICAP_USE_MOUNTED_CONFIG:-false}" == "true" ]]; then
            info "Using mounted configuration file"
            return 0
        fi
    fi

    return 1
}

########################
# Generate configuration
########################
generate_config() {
    if check_custom_config; then
        return 0
    fi

    info "Generating c-icap configuration from environment..."
    /opt/c-icap/generate-config.sh
}

########################
# Main
########################
main() {
    setup_env
    generate_config

    info "Starting c-icap daemon..."
    debug "Command: ${EXEC} -N -D -d ${CICAP_DEBUG_LEVEL:-1} -f ${CONFIG_FILE}"

    # -N: Do not run as daemon (stay in foreground)
    # -D: Print debug info to stdout
    # -d: Debug level
    # -f: Configuration file
    exec "${EXEC}" -N -D -d "${CICAP_DEBUG_LEVEL:-1}" -f "${CONFIG_FILE}"
}

main "$@"
