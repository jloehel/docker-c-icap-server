#!/bin/bash
# shellcheck shell=bash
# Install c-icap and squidclamav on Fedora

set -eux

# Install c-icap server and squidclamav
# squidclamav uses INSTREAM for proper TCP/network scanning (no shared filesystem needed)
# Fedora packages: c-icap-0.6.3, squidclamav-7.4
dnf install -y --setopt=install_weak_deps=False \
    c-icap \
    squidclamav

# Create NSS wrapper files (will be populated at runtime)
touch "${NSS_WRAPPER_PWD}"
touch "${NSS_WRAPPER_GROUP}"

# Backup original config for reference
cp -r /etc/c-icap /etc/c-icap.orig
[ -f /etc/squidclamav.conf ] && cp /etc/squidclamav.conf /etc/squidclamav.conf.orig

# Remove default configs (will be generated at runtime)
rm -f /etc/c-icap/c-icap.conf
rm -f /etc/squidclamav.conf

# Create symlink so squidclamav finds its config in /etc/c-icap/
# This allows us to manage permissions in one place
ln -sf /etc/c-icap/squidclamav.conf /etc/squidclamav.conf
