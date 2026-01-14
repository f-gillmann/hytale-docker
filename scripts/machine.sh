#!/bin/bash

source /scripts/env.sh
source /scripts/utils.sh

# Setup machine-id for Hardware UUID detection in the container.
# If /etc/machine-id is mounted from host (ro) or exists, we use that.
# Otherwise, we create a persistent one in data directory.
setup_machine_id() {
    MACHINE_ID_FILE="$DATA_DIR/.machine-id"

    # Check if /etc/machine-id already exists (mounted or created)
    if [ -f /etc/machine-id ] && [ -s /etc/machine-id ]; then
        log_info "Using existing machine-id for Hardware UUID detection"
        return
    fi

    # If not present, create persistent one in data directory
    if [ ! -f "$MACHINE_ID_FILE" ]; then
        log_info "Generating machine-id for Hardware UUID detection..."
        head -c 512 /dev/urandom | md5sum | awk '{print $1}' > "$MACHINE_ID_FILE"
        chmod 444 "$MACHINE_ID_FILE"
    else
        log_info "Using existing machine-id from data directory for Hardware UUID detection"
    fi

    # Copy to /etc/machine-id if it doesn't exist or contents differ
    if [ ! -f /etc/machine-id ] || ! cmp -s "$MACHINE_ID_FILE" /etc/machine-id; then
        cp "$MACHINE_ID_FILE" /etc/machine-id
        chmod 444 /etc/machine-id
    fi
}
