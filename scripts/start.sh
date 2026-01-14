#!/bin/bash

source /scripts/env.sh
source /scripts/utils.sh

: "${UID:=1000}"
: "${GID:=1000}"
: "${SKIP_CHOWN_DATA:=false}"

umask "${UMASK:=0002}"

chown_dirs() {
    local dirs=(
        "$DATA_DIR"
        "$HYTALE_HOME"
    )

    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            chown -R hytale:hytale "$dir"
        fi
    done
}

update_user_id() {
    if [[ -v UID ]]; then
        if [[ $UID != 0 ]]; then
            if [[ $UID != $(id -u hytale) ]]; then
                log_info "Changing uid of hytale to $UID"
                usermod -u "$UID" hytale
            fi
        else
            runAsUser=root
        fi
    fi
}

update_group_id() {
    if [[ -v GID ]]; then
        if [[ $GID != 0 ]]; then
            if [[ $GID != $(id -g hytale) ]]; then
                log_info "Changing gid of hytale to $GID"
                groupmod -o -g "$GID" hytale
            fi
        else
            runAsGroup=root
        fi
    fi
}

update_ownership() {
    local dirs=("$DATA_DIR" "$HYTALE_HOME")

    for dir in "${dirs[@]}"; do
        if isFalse "${SKIP_CHOWN_DATA}" && [[ $(stat -c "%u" "$dir") != "$UID" ]]; then
            log_info "Changing ownership of $dir to $UID ..."
            chown -R "${runAsUser}:${runAsGroup}" "$dir"
        fi
    done
}

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

    cd "$DATA_DIR/Server" || { log_error "Failed to change directory to $DATA_DIR/Server"; exit 1; }

    eval "java $(build_java_opts) -jar HytaleServer.jar $(build_server_args)"
}

if [ "$(id -u)" = 0 ]; then
    runAsUser=hytale
    runAsGroup=hytale

    update_user_id
    update_group_id
    update_ownership

    exec gosu "${runAsUser}:${runAsGroup}" bash -c \
        "source /scripts/env.sh && \
         source /scripts/utils.sh && \
         $(declare -f start_server) && \
         start_server"
else
    exec start_server "$@"
fi
