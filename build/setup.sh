#!/bin/sh

set -e

distro=$(grep ^ID= /etc/os-release | cut -d'=' -f2)
"$(dirname "$0")/os/${distro}".sh
