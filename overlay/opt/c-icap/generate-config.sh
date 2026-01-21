#!/bin/bash -e

# shellcheck source=/dev/null
. /opt/base/functions

CONFIG_FILE="/etc/c-icap/c-icap.conf"
SQUIDCLAMAV_CONF="/etc/c-icap/squidclamav.conf"

########################
# Generate main c-icap.conf
########################
generate_main_config() {
    info "Generating main c-icap configuration..."

    cat > "${CONFIG_FILE}" << EOF
# c-icap configuration - Auto-generated
# Do not edit manually - changes will be overwritten on container restart
# Use environment variables or mount a custom config file instead

# Server settings
PidFile ${CICAP_RUN}/c-icap.pid
CommandsSocket ${CICAP_RUN}/c-icap.ctl
Timeout ${CICAP_TIMEOUT:-300}
MaxKeepAliveRequests ${CICAP_MAX_KEEPALIVE_REQUESTS:-100}
KeepAliveTimeout ${CICAP_KEEPALIVE_TIMEOUT:-600}
StartServers ${CICAP_START_SERVERS:-3}
MaxServers ${CICAP_MAX_SERVERS:-10}
MinSpareThreads ${CICAP_MIN_SPARE_THREADS:-10}
MaxSpareThreads ${CICAP_MAX_SPARE_THREADS:-20}
ThreadsPerChild ${CICAP_THREADS_PER_CHILD:-10}
MaxRequestsPerChild ${CICAP_MAX_REQUESTS_PER_CHILD:-0}
Port ${CICAP_PORT:-1344}
EOF

    # Only set User/Group if running as root (c-icap will drop privileges)
    # When running as non-root, c-icap keeps the current user/group
    if [ "$EUID" -eq 0 ]; then
        cat >> "${CONFIG_FILE}" << EOF
User ${APP_USERNAME}
Group 0
EOF
    fi

    cat >> "${CONFIG_FILE}" << EOF

# Temp directories
TmpDir /tmp/c-icap

# Logging - stdout for Docker
ServerLog /proc/self/fd/2
AccessLog /proc/self/fd/1
DebugLevel ${CICAP_DEBUG_LEVEL:-1}

# Modules directory (Fedora paths)
ModulesDir /usr/lib64/c_icap
ServicesDir /usr/lib64/c_icap

# Templates for error pages
TemplateDir /usr/share/c_icap/templates
TemplateDefaultLanguage en

# Magic file for file type detection
LoadMagicFile /etc/c-icap/c-icap.magic

# ACLs
acl all src 0.0.0.0/0.0.0.0
acl PERMIT_REQUESTS type REQMOD RESPMOD OPTIONS
icap_access allow all PERMIT_REQUESTS

EOF

    # Add squidclamav service
    cat >> "${CONFIG_FILE}" << EOF
# SquidClamav service - uses INSTREAM for proper network scanning
# No shared filesystem required between c-icap and clamd!
Service squidclamav squidclamav.so
EOF

    # Add echo service if enabled (useful for debugging)
    if [[ "${CICAP_ENABLE_ECHO:-false}" == "true" ]]; then
        cat >> "${CONFIG_FILE}" << EOF

# Echo service (for debugging)
Service echo srv_echo.so
EOF
    fi

    info "Main c-icap configuration generated"
}

########################
# Generate squidclamav.conf
########################
generate_squidclamav_config() {
    info "Generating squidclamav configuration..."

    # Support multiple clamd hosts for failover (comma-separated)
    local clamd_hosts="${CICAP_CLAMD_HOSTS:-${CICAP_ANTIVIRUS_HOST:-clamav}}"
    local clamd_port="${CICAP_CLAMD_PORT:-${CICAP_ANTIVIRUS_PORT:-3310}}"

    cat > "${SQUIDCLAMAV_CONF}" << EOF
# squidclamav configuration - Auto-generated
# Uses INSTREAM to scan via TCP - no shared filesystem needed!

# Maximum file size to scan (0 = no limit, use clamd's StreamMaxLength)
maxsize ${CICAP_MAX_OBJECT_SIZE:-5000000}

# Redirect URL when virus found (disabled = use c-icap templates)
# redirect http://your-server/cgi-bin/clwarn.cgi

# ClamAV daemon connection via TCP (INSTREAM mode)
# Multiple hosts supported for failover (comma-separated)
# clamd_local must be commented out for TCP mode!
#clamd_local /var/run/clamav/clamd.sock
clamd_ip ${clamd_hosts}
clamd_port ${clamd_port}

# Connection timeout in seconds (1-3 recommended)
# On timeout, switches to next clamd host if configured
timeout ${CICAP_CLAMD_TIMEOUT:-3}

# Log virus detections to c-icap log
logredir ${CICAP_LOG_REDIRECT:-1}

# DNS lookup of client IP (0 = disabled for performance)
dnslookup ${CICAP_DNS_LOOKUP:-0}

# Enable/disable Safe Browsing (requires ClamAV SafeBrowsing signatures)
safebrowsing ${CICAP_SAFE_BROWSING:-0}

EOF

    # Add whitelist patterns if provided
    if [[ -n "${CICAP_WHITELIST_HOSTS:-}" ]]; then
        echo "# Whitelisted hosts (no scanning)" >> "${SQUIDCLAMAV_CONF}"
        for host in ${CICAP_WHITELIST_HOSTS//,/ }; do
            echo "whitelist ${host}" >> "${SQUIDCLAMAV_CONF}"
        done
        echo "" >> "${SQUIDCLAMAV_CONF}"
    fi

    # Add trustclient patterns if provided (bypass scanning for trusted clients)
    if [[ -n "${CICAP_TRUSTCLIENT:-}" ]]; then
        echo "# Trusted clients (no scanning)" >> "${SQUIDCLAMAV_CONF}"
        for client in ${CICAP_TRUSTCLIENT//,/ }; do
            echo "trustclient ${client}" >> "${SQUIDCLAMAV_CONF}"
        done
        echo "" >> "${SQUIDCLAMAV_CONF}"
    fi

    # Add abort patterns for performance (skip scanning certain content types)
    cat >> "${SQUIDCLAMAV_CONF}" << 'EOF'
# Performance: Skip scanning images
abortcontent ^image\/.*$

# Performance: Skip scanning CSS/JS (optional, uncomment if needed)
#abortcontent ^text\/css$
#abortcontent ^application\/javascript$
#abortcontent ^application\/x-javascript$

# Performance: Skip scanning video/audio streams
abortcontent ^video\/.*$
abortcontent ^audio\/.*$
EOF

    info "squidclamav configuration generated"
}

########################
# Main
########################
main() {
    generate_main_config
    generate_squidclamav_config

    info "Configuration generation complete"
    debug "Main config: ${CONFIG_FILE}"
    debug "SquidClamav config: ${SQUIDCLAMAV_CONF}"
}

main "$@"
