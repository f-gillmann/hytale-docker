#!/bin/bash

# ===> Argument Helpers --------------------------------------------------------
# Use an Array for safe argument handling (handles spaces/quotes automatically)
SERVER_ARGS=()

# Syntax: def_arg VAR_NAME DEFAULT_VALUE FLAG_NAME
def_arg() {
    local var="$1" default="$2" flag="$3"
    # Set the export (defaulting if unset)
    export "$var"="${!var:-$default}"
    # If the value is not empty, add flag and value to args
    if [ -n "${!var}" ]; then
        SERVER_ARGS+=("$flag" "${!var}")
    fi
}

# Syntax: def_bool VAR_NAME DEFAULT_VALUE FLAG_NAME
def_bool() {
    local var="$1" default="$2" flag="$3"
    export "$var"="${!var:-$default}"
    # If explicitly "true", add the flag
    if [ "${!var}" == "true" ]; then
        SERVER_ARGS+=("$flag")
    fi
}

# ===> Paths & System ----------------------------------------------------------
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

# ===> Hytale Server Config ----------------------------------------------------
# --- Assets
def_arg  ASSETS_PATH            "$DATA_DIR/Assets.zip"  --assets                    # Asset directory (default: ../HytaleAssets)
def_arg  PREFAB_CACHE           ""                      --prefab-cache              # Prefab cache directory for immutable assets
def_arg  WORLD_GEN              ""                      --world-gen                 # World gen directory
def_arg  MODS_PATH              ""                      --mods                      # Additional mods directories

# --- Authentication
def_arg  AUTH_MODE              "authenticated"         --auth-mode                 # Authentication mode (authenticated|offline|insecure) (default: authenticated)
def_arg  IDENTITY_TOKEN         ""                      --identity-token            # Identity token (JWT)
def_arg  SESSION_TOKEN          ""                      --session-token             # Session token for Session Service API

# --- Plugins
def_bool ACCEPT_EARLY_PLUGINS   "false"                 --accept-early-plugins      # You acknowledge that loading early plugins is unsupported and may cause stability issues (true|false)
def_arg  EARLY_PLUGINS          ""                      --early-plugins             # Additional early plugin directories to load from

# --- Permissions
def_bool ALLOW_OP               "false"                 --allow-op                  # (true|false)

# --- Universe
def_arg  UNIVERSE_PATH          "$DATA_DIR/universe"    --universe

# --- Server Mode
def_bool BARE_MODE              "false"                 --bare                      # Runs the server bare (without loading worlds, binding to ports, creating directories) (true|false)
def_bool SINGLEPLAYER           "false"                 --singleplayer              # (true|false)

# --- Validation & Migration
def_bool VALIDATE_ASSETS          "false"               --validate-assets           # Causes the server to exit with an error code if any assets are invalid (true|false)
def_arg  VALIDATE_PREFABS         ""                    --validate-prefabs          # Causes the server to exit with an error code if any prefabs are invalid [ValidationOption]
def_bool VALIDATE_WORLD_GEN       "false"               --validate-world-gen        # Causes the server to exit with an error code if default world gen is invalid (true|false)
def_bool SHUTDOWN_AFTER_VALIDATE  "false"               --shutdown-after-validate   # Automatically shutdown the server after asset and/or prefab validation (true|false)
def_arg  MIGRATE_WORLDS           ""                    --migrate-worlds            # Worlds to migrate

# --- Boot & Startup
def_arg  BOOT_COMMAND           ""                      --boot-command              # Runs command on boot (multiple commands executed synchronously in order)
def_bool GENERATE_SCHEMA        "false"                 --generate-schema           # Causes the server generate schema, save it into assets directory and then exit (true|false)

# --- Advanced
def_bool DISABLE_SENTRY         "false"                 --disable-sentry            # (true|false)
def_bool DISABLE_ASSET_COMPARE  "false"                 --disable-asset-compare     # (true|false)
def_bool DISABLE_CPB_BUILD      "false"                 --disable-cpb-build         # Disables building of compact prefab buffers (true|false)
def_bool DISABLE_FILE_WATCHER   "false"                 --disable-file-watcher      # (true|false)
def_bool EVENT_DEBUG            "false"                 --event-debug               # (true|false)
def_arg  OWNER_NAME             ""                      --owner-name
def_arg  OWNER_UUID             ""                      --owner-uuid
def_arg  CLIENT_PID             ""                      --client-pid

# --- Logging
def_arg  LOG_LEVEL              ""                      --log                       # Sets the logger level


# ===> Manual Handling -----------------------------------------------
export SERVER_BIND_IP="${SERVER_BIND_IP:-0.0.0.0}"          # Server bind IP (default:0.0.0.0)
export SERVER_PORT="${SERVER_PORT:-5520}"                   # Server port (default: 5520)
export SERVER_TRANSPORT="${SERVER_TRANSPORT:-QUIC}"         # Transport type (QUIC|TCP) (default: QUIC)

export BACKUP_ENABLED="${BACKUP_ENABLED:-false}"            # Enable server backups (true|false)
export BACKUP_DIR="${BACKUP_DIR:-}"                         # Directory to store backups
export BACKUP_FREQUENCY="${BACKUP_FREQUENCY:-30}"           # Backup frequency in minutes (default: 30)
export BACKUP_MAX_COUNT="${BACKUP_MAX_COUNT:-5}"            # Maximum number of backups to keep (default: 5)

export FORCE_NETWORK_FLUSH="${FORCE_NETWORK_FLUSH:-true}"   # Force network flush (true|false) (default: true)
export EXTRA_ARGS="${EXTRA_ARGS:-}"                         # Extra arguments to pass to the server

# ===> Build Functions ---------------------------------------------------------
build_java_opts() {
    local opts="$JAVA_OPTS"
    [ -n "$JAVA_XMS" ] && opts="$opts -Xms$JAVA_XMS"
    [ -n "$JAVA_XMX" ] && opts="$opts -Xmx$JAVA_XMX"
    echo "$opts"
}

build_server_args() {
    # 1. Start with the auto-generated list
    local final_args=("${SERVER_ARGS[@]}")

    # 2. Add Complex/Manual Args
    final_args+=( "--bind" "$SERVER_BIND_IP:$SERVER_PORT" )
    final_args+=( "--transport" "$SERVER_TRANSPORT" )

    # Backups Logic
    if [ "$BACKUP_ENABLED" == "true" ]; then
        final_args+=( "--backup" )
        [ -n "$BACKUP_DIR" ] && final_args+=( "--backup-dir" "$BACKUP_DIR" )

        # Only add frequency/count if they differ from default to keep args clean
        [ "$BACKUP_FREQUENCY" != "30" ] && final_args+=( "--backup-frequency" "$BACKUP_FREQUENCY" )
        [ "$BACKUP_MAX_COUNT" != "5" ] && final_args+=( "--backup-max-count" "$BACKUP_MAX_COUNT" )
    fi

    # Inverted Logic Flag (Force Network Flush)
    if [ "$FORCE_NETWORK_FLUSH" == "false" ]; then
        final_args+=( "--force-network-flush" "false" )
    fi

    # Extra Args
    if [ -n "$EXTRA_ARGS" ]; then
        final_args+=( "$EXTRA_ARGS" )
    fi

    # Output the final array as a string
    echo "${final_args[@]}"
}
