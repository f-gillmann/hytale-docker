#!/bin/bash

# ===> Colors ------------------------------------------------------------------
RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'

# ===> Logging -----------------------------------------------------------------
log_info() {
    echo -e "[$(date +'%H:%M:%S')] ${GREEN}[INFO]${RESET} $1"
}

log_warn() {
    echo -e "[$(date +'%H:%M:%S')] ${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "[$(date +'%H:%M:%S')] ${RED}[ERRO]${RESET} $1"
}

# ===> Other -------------------------------------------------------------------
download_file() {
    local url=$1
    local output=$2

    log_info "Downloading from $url to $output..."

    if ! curl -L -o "$output" "$url"; then
        log_error "Download failed for $url."
        exit 1
    fi

    chmod +x "$output"
}
