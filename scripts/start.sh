#!/bin/bash

source /scripts/env.sh
source /scripts/utils.sh

start_server() {
    local jar_path="$DATA_DIR/Server/HytaleServer.jar"

    if [ ! -f "$jar_path" ]; then
        log_error "HytaleServer.jar not found at $jar_path"
        exit 1
    fi

    if [ ! -f "$ASSETS_PATH" ]; then
        log_error "Assets not found at $ASSETS_PATH"
        exit 1
    fi

    log_info "Starting Hytale Server..."
    log_info "  Bind: $SERVER_BIND_IP:$SERVER_PORT"
    log_info "  Assets Path: $ASSETS_PATH"
    log_info "  Java Options: $(build_java_opts)"
    log_info "  Server Arguments: $(build_server_args)"

    cd "$DATA_DIR/Server" || exit 1

    eval "java $(build_java_opts) -jar HytaleServer.jar $(build_server_args)"
}

# Run if directly executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    start_server
fi
