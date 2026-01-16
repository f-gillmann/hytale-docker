#!/bin/sh

set -e

distro=$(grep ^ID= /etc/os-release | cut -d'=' -f2)

# Set up user
"$(dirname "$0")/${distro}/"user.sh

# Install dependencies
"$(dirname "$0")/${distro}/"dependencies.sh
