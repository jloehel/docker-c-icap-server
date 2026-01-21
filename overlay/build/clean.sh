#!/bin/bash
# shellcheck shell=bash
# Clean up after installation to reduce image size

set -eux

# Clean dnf cache
dnf clean all
rm -rf /var/cache/dnf/*

# Remove build directory
rm -rf /build

# Remove logs
rm -rf /var/log/*.log /var/log/dnf*

# Remove documentation to save space
rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*

# Remove locales (keep only C and POSIX)
rm -rf /usr/share/locale/* /usr/share/i18n/*

# Remove other unnecessary files
rm -rf /tmp/* /var/tmp/*
