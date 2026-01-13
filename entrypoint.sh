#!/bin/bash
set -e

# Load modules
source /scripts/env.sh
source /scripts/utils.sh
source /scripts/updater.sh

log_info "=== Hytale Docker Container ==="

# Ensure directories exist
mkdir -p "$DATA_DIR"
mkdir -p "$HYTALE_HOME"

# Run the update/download flow
run_updater

# Start the server
source /scripts/start.sh
start_server
