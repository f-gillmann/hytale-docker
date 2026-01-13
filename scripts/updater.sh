#!/bin/bash

source /scripts/env.sh
source /scripts/utils.sh

ensure_downloader() {
    if [ ! -f "$HYTALE_HOME/$DOWNLOADER_BIN" ]; then
        local temp_zip
        temp_zip=$(mktemp)

        log_info "Downloading hytale-downloader..."
        download_file "$DOWNLOADER_URL" "$temp_zip"

        # Extract the linux binary
        local binary_name="hytale-downloader-linux-amd64"
        unzip -o -q "$temp_zip" "$binary_name" -d "$HYTALE_HOME"
        mv "$HYTALE_HOME/$binary_name" "$HYTALE_HOME/$DOWNLOADER_BIN"
        chmod +x "$HYTALE_HOME/$DOWNLOADER_BIN"

        rm -f "$temp_zip"
        log_info "Downloader ready"
    fi
}

update_downloader() {
    if isTrue "$SKIP_DOWNLOADER_UPDATE"; then
        log_info "Skipping downloader update check"
        return
    fi

    log_info "Checking for downloader updates..."

    local output
    if ! output=$("$HYTALE_HOME/$DOWNLOADER_BIN" -check-update 2>&1); then
        log_warn "Failed to check for downloader updates"
        return
    fi

    if [[ "$output" == *"A new version"* ]]; then
        # Parse and display update information
        log_info "$output"
        log_info "Updating downloader..."

        local temp_zip
        temp_zip=$(mktemp)

        download_file "$DOWNLOADER_URL" "$temp_zip"

        local binary_name="hytale-downloader-linux-amd64"
        unzip -o -q "$temp_zip" "$binary_name" -d "$HYTALE_HOME"
        mv "$HYTALE_HOME/$binary_name" "$HYTALE_HOME/$DOWNLOADER_BIN"
        chmod +x "$HYTALE_HOME/$DOWNLOADER_BIN"

        rm -f "$temp_zip"
        log_info "Downloader updated successfully"
    else
        log_info "Downloader is up to date"
    fi
}

setup_credentials() {
    # Ensure HYTALE_HOME directory exists
    mkdir -p "$HYTALE_HOME" || { log_error "Failed to create $HYTALE_HOME"; exit 1; }

    # Ensure DATA_DIR exists
    mkdir -p "$DATA_DIR" || { log_error "Failed to create $DATA_DIR"; exit 1; }

    # Credentials will be stored in DATA_DIR (mounted volume) using -credentials-path argument
    log_info "Credentials will be stored at $CREDENTIALS_FILE"
}

check_game_version() {
    # Only check version if credentials exist
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        log_info "No credentials found, skipping version check"
        return 1
    fi

    # Check if game files exist
    if [ ! -f "$DATA_DIR/Server/HytaleServer.jar" ]; then
        log_info "Game files not found, download required"
        return 1
    fi

    # Store version file path
    local version_file="$DATA_DIR/.game-version"

    # Get latest available version
    cd "$HYTALE_HOME" || { log_error "Failed to change directory to $HYTALE_HOME"; exit 1; }

    local latest_version
    if ! latest_version=$(./"$DOWNLOADER_BIN" \
        -credentials-path "$CREDENTIALS_FILE" \
        -print-version \
        -patchline "$PATCHLINE" 2>&1); then
        log_warn "Failed to check latest game version"
        return 1
    fi

    # Get installed version if available
    local installed_version=""
    if [ -f "$version_file" ]; then
        installed_version=$(cat "$version_file")
    fi

    log_info "Latest version: $latest_version"
    if [ -n "$installed_version" ]; then
        log_info "Installed version: $installed_version"
    fi

    # Compare versions
    if [ "$installed_version" == "$latest_version" ]; then
        log_info "Game files are up to date"
        return 0
    else
        log_info "Game files need to be updated"
        return 1
    fi
}

download_game() {
    if isFalse "$HYTALE_AUTO_DOWNLOAD"; then
        log_info "Auto-download disabled, skipping game download"
        return
    fi

    # Check if update is needed (only if credentials exist)
    if check_game_version; then
        return
    fi

    log_info "Downloading game files (patchline: $PATCHLINE)..."

    cd "$HYTALE_HOME" || { log_error "Failed to change directory to $HYTALE_HOME"; exit 1; }

    local game_zip
    game_zip=$(mktemp)

    if ! ./"$DOWNLOADER_BIN" \
        -credentials-path "$CREDENTIALS_FILE" \
        -patchline "$PATCHLINE" \
        -skip-update-check \
        -download-path "$game_zip"; then
        rm -f "$game_zip"
        log_error "Game download failed. Check authentication."
        exit 1
    fi

    # Extract if zip exists
    if [ -f "$game_zip" ]; then
        log_info "Extracting game files..."

        # Verify zip file integrity before extraction
        if ! unzip -t "$game_zip" > /dev/null 2>&1; then
            log_error "Zip file is corrupted or invalid"
            rm -f "$game_zip"
            exit 1
        fi

        if ! unzip -o "$game_zip" -d "$DATA_DIR"; then
            log_error "Failed to extract game files"
            rm -f "$game_zip"
            exit 1
        fi

        rm -f "$game_zip"
        log_info "Game files extracted"

        # Save version after successful download
        local latest_version
        if latest_version=$(./"$DOWNLOADER_BIN" \
            -credentials-path "$CREDENTIALS_FILE" \
            -print-version \
            -patchline "$PATCHLINE" 2>&1); then
            echo "$latest_version" > "$DATA_DIR/.game-version"
            log_info "Game version saved: $latest_version"
        fi
    fi
}

run_updater() {
    ensure_downloader
    setup_credentials
    update_downloader
    download_game
}
