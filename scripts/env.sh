#!/bin/bash

# Load utility functions
source /scripts/utils.sh

# ===> Argument Helpers --------------------------------------------------------------------------------------------------------------
JVM_ARGS=()
SERVER_ARGS=()

def_jvm_arg() {
    local var="$1" default="$2"
    export "$var"="${!var:-$default}"

    if [ -n "${!var}" ]; then
        JVM_ARGS+=("${!var}")
    fi
}

def_server_arg() {
    local var="$1" default="$2" flag="$3"
    export "$var"="${!var:-$default}"

    if [ -n "${!var}" ] && [ -n "$flag" ]; then
        SERVER_ARGS+=("$flag" "${!var}")
    fi
}

def_server_bool() {
    local var="$1" default="$2" flag="$3"
    export "$var"="${!var:-$default}"

    if [ "${!var}" == "true" ] && [ -n "$flag" ]; then
        SERVER_ARGS+=("$flag")
    fi
}

# ===> General Options ---------------------------------------------------------------------------------------------------------------
export UID="${UID:-1000}"                          # Linux user id to run as
export GID="${GID:-1000}"                          # Linux group id to run as
export UMASK="${UMASK:-0002}"                      # File creation umask
export TZ="${TZ:-UTC}"                             # Timezone
export SKIP_CHOWN_DATA="${SKIP_CHOWN_DATA:-false}" # Skip ownership change of data directory

# ===> Paths -------------------------------------------------------------------------------------------------------------------------
export HYTALE_HOME="/opt/hytale}"                                                            # Hytale installation directory
export DATA_DIR="/data"                                                                      # Main data directory
export SERVER_HOME="$DATA_DIR"                                                               # Server working directory
export CREDENTIALS_FILE="${CREDENTIALS_FILE:-$DATA_DIR/.hytale-downloader-credentials.json}" # Downloader credentials

# ===> Downloader --------------------------------------------------------------------------------------------------------------------
export AUTO_DOWNLOAD="${AUTO_DOWNLOAD:-true}"                                 # Auto-download server files
export PATCHLINE="${PATCHLINE:-release}"                                      # Download patchline (release/beta/alpha)
export SKIP_DOWNLOADER_UPDATE="${SKIP_DOWNLOADER_UPDATE:-false}"              # Skip downloader updates
export DOWNLOADER_BIN="hytale-downloader"                                     # Downloader binary name
export DOWNLOADER_URL="https://downloader.hytale.com/hytale-downloader.zip"   # Downloader download URL

# ===> JVM Configuration -------------------------------------------------------------------------------------------------------------
# Memory settings
def_jvm_arg MIN_MEMORY                  "${MIN_MEMORY:-}"                     # JVM initial heap size (-Xms)
def_jvm_arg MAX_MEMORY                  "${MAX_MEMORY:-}"                     # JVM maximum heap size (-Xmx)

# Extra JVM options
export EXTRA_JVM_OPTS="${JVM_OPTS:-}"                                         # Extra JVM options

# ===> Logging -----------------------------------------------------------------------------------------------------------------------
def_server_arg LOG_LEVEL                "info"                 --log          # Root logger level (trace, debug, info, warn, error)
export LOG_TIMESTAMP="${LOG_TIMESTAMP:-false}"                                # Include timestamp in logs

# ===> Server Network ----------------------------------------------------------------------------------------------------------------
def_server_arg SERVER_BIND_IP           "0.0.0.0"              ""             # Server bind IP (handled specially in build_server_args)
def_server_arg SERVER_PORT              "5520"                 ""             # Server port (handled specially in build_server_args)
def_server_arg TRANSPORT                "QUIC"                 --transport    # Transport type (QUIC/TCP)

# ===> Hytale Configuration ----------------------------------------------------------------------------------------------------------
# Assets & Resources
def_server_arg ASSETS_PATH              "$DATA_DIR/Assets.zip" --assets       # Asset directory
def_server_arg PREFAB_CACHE             ""                     --prefab-cache # Prefab cache directory for immutable assets
def_server_arg WORLD_GEN                ""                     --world-gen    # World generation directory
def_server_arg MODS_PATH                ""                     --mods         # Additional mods directories

# Universe & World
def_server_arg UNIVERSE_PATH            "$DATA_DIR/universe" --universe       # Universe data directory

# Authentication
def_server_arg AUTH_MODE                "authenticated" --auth-mode           # Authentication mode (authenticated/offline/insecure)
def_server_arg IDENTITY_TOKEN           ""              --identity-token      # Identity token
def_server_arg SESSION_TOKEN            ""              --session-token       # Session token for Session Service API

# Server Mode
def_server_bool BARE_MODE               "false"     --bare                    # Run server in bare mode
def_server_bool SINGLEPLAYER            "false"     --singleplayer            # Enable singleplayer mode

# Permissions
def_server_bool ALLOW_OP                "false"     --allow-op                # Allow operator permissions

# Plugins & Mods
def_server_bool ACCEPT_EARLY_PLUGINS    "false"     --accept-early-plugins    # You acknowledge that loading early plugins is unsupported and may cause stability issues.
def_server_arg  EARLY_PLUGINS           ""          --early-plugins           # Early plugin directories

# Backups
def_server_bool BACKUP_ENABLED          "false"     ""                        # Enable automatic backups

if isTrue "$BACKUP_ENABLED"; then
    def_server_arg  BACKUP_DIR          ""          --backup-dir              # Backup storage directory
    def_server_arg  BACKUP_FREQUENCY    ""          --backup-frequency        # Backup frequency in minutes
    def_server_arg  BACKUP_MAX_COUNT    ""          --backup-max-count        # Maximum number of backups to keep
fi

# Network
def_server_arg FORCE_NETWORK_FLUSH      "true"      --force-network-flush      # Force network flush (true/false)

# Validation & Migration
def_server_bool VALIDATE_ASSETS         "false"     --validate-assets         # Validate assets on startup
def_server_arg  VALIDATE_PREFABS        ""          --validate-prefabs        # Validate prefabs (ValidationOption)
def_server_bool VALIDATE_WORLD_GEN      "false"     --validate-world-gen      # Validate world generation
def_server_bool SHUTDOWN_AFTER_VALIDATE "false"     --shutdown-after-validate # Auto-shutdown after validation
def_server_arg  MIGRATE_WORLDS          ""          --migrate-worlds          # Worlds to migrate

# Boot
def_server_arg  BOOT_COMMAND            ""          --boot-command            # Command to run on boot
def_server_bool GENERATE_SCHEMA         "false"     --generate-schema         # Generate schema and exit

# Debugging & Development
def_server_bool DISABLE_SENTRY          "false"     --disable-sentry          # Disable Sentry error reporting
def_server_bool DISABLE_ASSET_COMPARE   "false"     --disable-asset-compare   # Disable asset comparison
def_server_bool DISABLE_CPB_BUILD       "false"     --disable-cpb-build       # Disable compact prefab buffer building
def_server_bool DISABLE_FILE_WATCHER    "false"     --disable-file-watcher    # Disable file watcher
def_server_bool EVENT_DEBUG             "false"     --event-debug             # Enable event debugging

# Server ownership
def_server_arg  OWNER_NAME              ""          --owner-name              # Server owner name
def_server_arg  OWNER_UUID              ""          --owner-uuid              # Server owner UUID
def_server_arg  CLIENT_PID              ""          --client-pid              # Client process ID

# ===> Extra Arguments ---------------------------------------------------------------------------------------------------------------
export EXTRA_ARGS="${EXTRA_ARGS:-}"                                           # Extra arguments to pass to the server

# ===> Build Functions ---------------------------------------------------------------------------------------------------------------
build_java_opts() {
    local java_opts=()

    # Memory settings
    [ -n "$MIN_MEMORY" ] && java_opts+=("-Xms$MIN_MEMORY")
    [ -n "$MAX_MEMORY" ] && java_opts+=("-Xmx$MAX_MEMORY")

    # Add any additional args from JVM_ARGS array
    java_opts+=("${JVM_ARGS[@]}")

    echo "${java_opts[@]}"
}

build_server_args() {
    local final_args=("${SERVER_ARGS[@]}")

    final_args+=("--bind" "$SERVER_BIND_IP:$SERVER_PORT")

    if [ "$BACKUP_ENABLED" == "true" ]; then
        final_args+=("--backup")
    fi

    # Add any extra args provided
    if [ -n "$EXTRA_ARGS" ]; then
        eval "final_args+=($EXTRA_ARGS)"
    fi

    echo "${final_args[@]}"
}
