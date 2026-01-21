#!/bin/bash
# shellcheck shell=bash
# Install system dependencies for Fedora

set -eux

dnf install -y --setopt=install_weak_deps=False \
    tini \
    nss_wrapper \
    ca-certificates
