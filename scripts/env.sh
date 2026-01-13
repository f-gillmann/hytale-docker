#!/bin/bash

# ===> Paths -------------------------------------------------------------------
export HYTALE_HOME="${HYTALE_HOME:-/opt/hytale}"
export DATA_DIR="${DATA_DIR:-/data}"
export CREDENTIALS_FILE="${CREDENTIALS_FILE:-$DATA_DIR/.hytale-downloader-credentials.json}"
export SERVER_HOME="${SERVER_HOME:-$DATA_DIR}"
export MODS_DIR="${MODS_DIR:-$DATA_DIR/mods}"
export UNIVERSE_DIR="${UNIVERSE_DIR:-$DATA_DIR/universe}"

# ===> Downloader --------------------------------------------------------------
export HYTALE_AUTO_DOWNLOAD="${HYTALE_AUTO_DOWNLOAD:-true}"
export PATCHLINE="${PATCHLINE:-release}"
export SKIP_DOWNLOADER_UPDATE="${SKIP_DOWNLOADER_UPDATE:-false}"
export DOWNLOADER_BIN="hytale-downloader"
export DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"

# ===> JVM ---------------------------------------------------------------------
export JAVA_OPTS="${JAVA_OPTS}"
export JAVA_XMS="${JAVA_XMS:-}"
export JAVA_XMX="${JAVA_XMX:-}"

# ===> Hytale Server -----------------------------------------------------------
# --- Network
export SERVER_BIND_IP="${SERVER_BIND_IP:-0.0.0.0}"                  # Address to listen on (default: 0.0.0.0)
export SERVER_PORT="${SERVER_PORT:-5520}"                           # Port to listen on (default: 5520)
export SERVER_TRANSPORT="${SERVER_TRANSPORT:-QUIC}"                 # Transport type (default: QUIC)

# --- Assets
export ASSETS_PATH="${ASSETS_PATH:-$DATA_DIR/Assets.zip}"           # Asset directory (default: ../HytaleAssets)
export PREFAB_CACHE="${PREFAB_CACHE:-}"                             # Prefab cache directory for immutable assets
export WORLD_GEN="${WORLD_GEN:-}"                                   # World gen directory
export MODS_PATH="${MODS_PATH:-}"                                   # Additional mods directories

# --- Authentication
export AUTH_MODE="${AUTH_MODE:-authenticated}"                      # Authentication mode: authenticated, offline, or insecure (default: AUTHENTICATED)
export IDENTITY_TOKEN="${IDENTITY_TOKEN:-}"                         # Identity token (JWT)
export SESSION_TOKEN="${SESSION_TOKEN:-}"                           # Session token for Session Service API

# --- Plugins
export ACCEPT_EARLY_PLUGINS="${ACCEPT_EARLY_PLUGINS:-false}"        # Acknowledge that loading early plugins is unsupported and may cause stability issues
export EARLY_PLUGINS="${EARLY_PLUGINS:-}"                           # Additional early plugin directories to load from

# --- Permissions
export ALLOW_OP="${ALLOW_OP:-false}"                                # Allow OP permissions

# --- Backups
export BACKUP_ENABLED="${BACKUP_ENABLED:-false}"                    # Enable automatic backups
export BACKUP_DIR="${BACKUP_DIR:-}"                                 # Backup directory
export BACKUP_FREQUENCY="${BACKUP_FREQUENCY:-30}"                   # Backup interval in minutes (default: 30)
export BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-5}"                    # Maximum number of backups to keep (default: 5)

# --- Universe
export UNIVERSE_PATH="${UNIVERSE_PATH:-$DATA_DIR/universe}"         # Universe directory for world and player save data

# --- Server Mode
export BARE_MODE="${BARE_MODE:-false}"                              # Runs the server bare without loading worlds, binding to ports or creating directories
export SINGLEPLAYER="${SINGLEPLAYER:-false}"                        # Run in singleplayer mode

# --- Validation & Migration
export VALIDATE_ASSETS="${VALIDATE_ASSETS:-false}"                  # Causes the server to exit with an error code if any assets are invalid
export VALIDATE_PREFABS="${VALIDATE_PREFABS:-}"                     # Causes the server to exit with an error code if any prefabs are invalid
export VALIDATE_WORLD_GEN="${VALIDATE_WORLD_GEN:-false}"            # Causes the server to exit with an error code if default world gen is invalid
export SHUTDOWN_AFTER_VALIDATE="${SHUTDOWN_AFTER_VALIDATE:-false}"  # Automatically shutdown the server after asset and/or prefab validation
export MIGRATE_WORLDS="${MIGRATE_WORLDS:-}"                         # Worlds to migrate

# --- Boot & Startup
export BOOT_COMMAND="${BOOT_COMMAND:-}"                             # Runs command on boot. If multiple commands are provided they are executed synchronously in order
export GENERATE_SCHEMA="${GENERATE_SCHEMA:-false}"                  # Causes the server generate schema, save it into the assets directory and then exit

# --- Advanced
export DISABLE_SENTRY="${DISABLE_SENTRY:-false}"                    # Disable Sentry crash reporting
export DISABLE_ASSET_COMPARE="${DISABLE_ASSET_COMPARE:-false}"      # Disable asset comparison
export DISABLE_CPB_BUILD="${DISABLE_CPB_BUILD:-false}"              # Disables building of compact prefab buffers
export DISABLE_FILE_WATCHER="${DISABLE_FILE_WATCHER:-false}"        # Disable file watcher
export EVENT_DEBUG="${EVENT_DEBUG:-false}"                          # Enable event debugging
export FORCE_NETWORK_FLUSH="${FORCE_NETWORK_FLUSH:-true}"           # Force network flush (default: true)
export OWNER_NAME="${OWNER_NAME:-}"                                 # Server owner name
export OWNER_UUID="${OWNER_UUID:-}"                                 # Server owner UUID
export CLIENT_PID="${CLIENT_PID:-}"                                 # Client process ID

# --- Logging
export LOG_LEVEL="${LOG_LEVEL:-}"                                   # Sets the logger level (KeyValueHolder format)

# --- Other
export EXTRA_ARGS="${EXTRA_ARGS:-}"                                 # Extra arguments to pass to the server


# ===> Build Functions ---------------------------------------------------------
build_java_opts() {
    local opts="$JAVA_OPTS"

    if [ -n "$JAVA_XMS" ]; then
        opts="$opts -Xms$JAVA_XMS"
    fi

    if [ -n "$JAVA_XMX" ]; then
        opts="$opts -Xmx$JAVA_XMX"
    fi

    echo "$opts"
}

build_server_args() {
    local args=""

    # Network
    args="$args --bind $SERVER_BIND_IP:$SERVER_PORT"
    args="$args --transport $SERVER_TRANSPORT"

    # Assets
    args="$args --assets $ASSETS_PATH"
    if [ -n "$PREFAB_CACHE" ]; then
        args="$args --prefab-cache $PREFAB_CACHE"
    fi
    if [ -n "$WORLD_GEN" ]; then
        args="$args --world-gen $WORLD_GEN"
    fi
    if [ -n "$MODS_PATH" ]; then
        args="$args --mods $MODS_PATH"
    fi

    # Authentication
    if [ -n "$AUTH_MODE" ]; then
        args="$args --auth-mode $AUTH_MODE"
    fi
    if [ -n "$IDENTITY_TOKEN" ]; then
        args="$args --identity-token $IDENTITY_TOKEN"
    fi
    if [ -n "$SESSION_TOKEN" ]; then
        args="$args --session-token $SESSION_TOKEN"
    fi

    # Plugins
    if isTrue "$ACCEPT_EARLY_PLUGINS"; then
        args="$args --accept-early-plugins"
    fi
    if [ -n "$EARLY_PLUGINS" ]; then
        args="$args --early-plugins $EARLY_PLUGINS"
    fi

    # Permissions
    if isTrue "$ALLOW_OP"; then
        args="$args --allow-op"
    fi

    # Backups
    if isTrue "$BACKUP_ENABLED"; then
        args="$args --backup"
        if [ -n "$BACKUP_DIR" ]; then
            args="$args --backup-dir $BACKUP_DIR"
        fi
        if [ "$BACKUP_FREQUENCY" != "30" ]; then
            args="$args --backup-frequency $BACKUP_FREQUENCY"
        fi
        if [ "$BACKUP_MAX_COUNT" != "5" ]; then
            args="$args --backup-max-count $BACKUP_MAX_COUNT"
        fi
    fi

    # Universe
    if [ -n "$UNIVERSE_PATH" ]; then
        args="$args --universe $UNIVERSE_PATH"
    fi

    # Server Mode
    if isTrue "$BARE_MODE"; then
        args="$args --bare"
    fi
    if isTrue "$SINGLEPLAYER"; then
        args="$args --singleplayer"
    fi

    # Validation & Migration
    if isTrue "$VALIDATE_ASSETS"; then
        args="$args --validate-assets"
    fi
    if [ -n "$VALIDATE_PREFABS" ]; then
        args="$args --validate-prefabs $VALIDATE_PREFABS"
    fi
    if isTrue "$VALIDATE_WORLD_GEN"; then
        args="$args --validate-world-gen"
    fi
    if isTrue "$SHUTDOWN_AFTER_VALIDATE"; then
        args="$args --shutdown-after-validate"
    fi
    if [ -n "$MIGRATE_WORLDS" ]; then
        args="$args --migrate-worlds $MIGRATE_WORLDS"
    fi

    # Boot & Startup
    if [ -n "$BOOT_COMMAND" ]; then
        args="$args --boot-command \"$BOOT_COMMAND\""
    fi
    if isTrue "$GENERATE_SCHEMA"; then
        args="$args --generate-schema"
    fi

    # Advanced
    if isTrue "$DISABLE_SENTRY"; then
        args="$args --disable-sentry"
    fi
    if isTrue "$DISABLE_ASSET_COMPARE"; then
        args="$args --disable-asset-compare"
    fi
    if isTrue "$DISABLE_CPB_BUILD"; then
        args="$args --disable-cpb-build"
    fi
    if isTrue "$DISABLE_FILE_WATCHER"; then
        args="$args --disable-file-watcher"
    fi
    if isTrue "$EVENT_DEBUG"; then
        args="$args --event-debug"
    fi
    if isFalse "$FORCE_NETWORK_FLUSH"; then
        args="$args --force-network-flush $FORCE_NETWORK_FLUSH"
    fi
    if [ -n "$OWNER_NAME" ]; then
        args="$args --owner-name $OWNER_NAME"
    fi
    if [ -n "$OWNER_UUID" ]; then
        args="$args --owner-uuid $OWNER_UUID"
    fi
    if [ -n "$CLIENT_PID" ]; then
        args="$args --client-pid $CLIENT_PID"
    fi

    # Logging
    if [ -n "$LOG_LEVEL" ]; then
        args="$args --log $LOG_LEVEL"
    fi

    # Extra args
    if [ -n "$EXTRA_ARGS" ]; then
        args="$args $EXTRA_ARGS"
    fi

    echo "$args"
}
