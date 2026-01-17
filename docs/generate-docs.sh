#!/bin/bash

# Script to automatically generate documentation from env.sh
# Parses def_server_arg, def_server_bool, and other variable definitions

ENV_FILE="$(dirname "$0")/../scripts/env.sh"
OUTPUT_FILE="$(dirname "$0")/src/content/docs/reference/variables.mdx"

# Check if env.sh exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: env.sh not found at $ENV_FILE"
    exit 1
fi

# Start building the MDX content
cat > "$OUTPUT_FILE" <<'HEADER'
---
title: Environment Variables
description: Complete reference for all user-configurable environment variables
---

import {Aside} from '@astrojs/starlight/components';

<Aside type="note">
This documentation is auto-generated from [`env.sh`](https://github.com/f-gillmann/hytale-docker/blob/master/scripts/env.sh).
</Aside>

This page provides a reference for all environment variables that can be used to configure your Hytale server container.

<Aside type="tip">
These variables can be set in your `docker-compose.yml` file under the `environment` section, or passed with `-e` flag when using `docker run`.
</Aside>
HEADER

# Function to add a section
add_section() {
    local section_title="$1"
    local section_desc="$2"

    cat >> "$OUTPUT_FILE" <<EOF

## $section_title

$section_desc

| Variable | Default | Description |
|----------|---------|-------------|
EOF
}

# Function to add a subsection
add_subsection() {
    local subsection_title="$1"

    cat >> "$OUTPUT_FILE" <<EOF

### $subsection_title

| Variable | Default | Description |
|----------|---------|-------------|
EOF
}

# Function to add a table row
add_row() {
    local var="$1"
    local default="$2"
    local desc="$3"

    # Escape pipe characters in description
    desc="${desc//|/\|}"

    # Format default value - skip backticks if empty
    local default_formatted
    if [ -z "$default" ]; then
        default_formatted=""
    else
        default_formatted="\`$default\`"
    fi

    echo "| \`$var\` | $default_formatted | $desc |" >> "$OUTPUT_FILE"
}

# Helper function to clean default values
clean_default() {
    local val="$1"
    # Remove shell variable syntax ${VAR:-value} -> value
    val="${val//\$\{*:-/}"
    val="${val//\}/}"
    # Replace $DATA_DIR with /data
    val="${val//\$DATA_DIR/\/data}"
    # Replace $MEMORY with actual value
    val="${val//\$MEMORY/4G}"
    echo "$val"
}

# Parse env.sh and extract variable definitions
parse_env_file() {
    local current_section=""
    local in_user_section=false
    local in_hytale_config=false

    while IFS= read -r line; do
        # Detect section headers (comments starting with ===>)
        if [[ $line =~ "# ===>" ]]; then
            # Extract section name
            local temp_section
            temp_section=$(echo "$line" | sed -E 's/.*===>[[:space:]]*([^-]+).*/\1/' | xargs)
            current_section="$temp_section"

            # Skip internal sections that users shouldn't modify
            case "$current_section" in
                "Argument Helpers"|"Build Functions"|"Paths")
                    in_user_section=false
                    in_hytale_config=false
                    ;;
                "Container Options")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "Container Options" "Configure container runtime behavior and user permissions."
                    ;;
                "Downloader")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "Downloader Configuration" "Configure automatic server file downloads and updates."
                    ;;
                "JVM Configuration")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "JVM Configuration" "Control JVM memory settings and options."
                    ;;
                "Logging")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "Logging" "Configure server logging behavior."
                    ;;
                "Server Network")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "Network Configuration" "Set server ports and network-related options."
                    ;;
                "Hytale Configuration")
                    in_user_section=true
                    in_hytale_config=true
                    add_section "Server Configuration" "Core Hytale server settings."
                    ;;
                "Extra Arguments")
                    in_user_section=true
                    in_hytale_config=false
                    add_section "Extra Arguments" "Pass additional custom arguments to the server."
                    ;;
                *)
                    in_user_section=false
                    in_hytale_config=false
                    ;;
            esac
            continue
        fi

        # Skip if not in a user-configurable section
        [ "$in_user_section" = false ] && continue

        # Extract inline comments for description
        local comment=""
        if [[ $line == *"#"* ]]; then
            # Extract everything after the first # character
            comment="${line#*#}"
            # Trim leading whitespace
            comment="${comment#"${comment%%[![:space:]]*}"}"
        fi

        # Detect subsections within Hytale Configuration by checking inline comments
        if [ "$in_hytale_config" = true ]; then
            # Detect subsection markers (standalone comments before variable definitions)
            if [[ $line =~ ^[[:space:]]*#[[:space:]]+(Assets|Universe|Authentication|Server\ Mode|Permissions|Plugins|Backups|Network|Validation|Boot|Debugging|Server\ ownership) ]]; then
                local temp_subsection
                temp_subsection=$(echo "$line" | sed -E 's/^[[:space:]]*#[[:space:]]+([^&]+).*/\1/' | xargs)
                local subsection="$temp_subsection"
                case "$subsection" in
                    Assets*)
                        add_subsection "Assets & Resources"
                        ;;
                    Universe*)
                        add_subsection "Universe & World"
                        ;;
                    Authentication)
                        add_subsection "Authentication"
                        ;;
                    "Server Mode")
                        add_subsection "Server Mode"
                        ;;
                    Permissions)
                        add_subsection "Permissions"
                        ;;
                    Plugins*)
                        add_subsection "Plugins & Mods"
                        ;;
                    Backups)
                        add_subsection "Backups"
                        ;;
                    Network)
                        add_subsection "Network Options"
                        ;;
                    Validation*)
                        add_subsection "Validation & Migration"
                        ;;
                    Boot)
                        add_subsection "Boot Configuration"
                        ;;
                    Debugging*)
                        add_subsection "Debugging & Development"
                        ;;
                    "Server Ownership")
                        add_subsection "Server Ownership"
                        ;;
                esac
                continue
            fi
        fi

        # Parse def_server_arg lines
        if [[ $line =~ def_server_arg ]]; then
            local var
            local default
            var=$(echo "$line" | awk '{print $2}')
            default=$(echo "$line" | grep -oP '"\K[^"]*' | head -1)
            default=$(clean_default "$default")
            add_row "$var" "$default" "$comment"
        # Parse def_server_bool lines
        elif [[ $line =~ def_server_bool ]]; then
            local var
            local default
            var=$(echo "$line" | awk '{print $2}')
            default=$(echo "$line" | grep -oP '"\K[^"]*' | head -1)
            default=$(clean_default "$default")
            add_row "$var" "$default" "$comment"
        # Parse def_var lines
        elif [[ $line =~ ^def_var ]]; then
            local var
            local default
            var=$(echo "$line" | awk '{print $2}')
            default=$(echo "$line" | grep -oP '"\K[^"]*' | head -1)
            default=$(clean_default "$default")
            add_row "$var" "$default" "$comment"
        # Parse specific export lines for container options, downloader, and extra args sections
        elif [[ $line =~ ^export[[:space:]]+(UID|GID|TZ|SKIP_CHOWN_DATA|AUTO_DOWNLOAD|PATCHLINE|SKIP_DOWNLOADER_UPDATE|EXTRA_ARGS) ]]; then
            local var
            local default
            var=$(echo "$line" | sed -E 's/export[[:space:]]+([A-Z_]+)=.*/\1/')
            default=$(echo "$line" | grep -oP ':-\K[^}]+' | head -1)
            default=$(clean_default "$default")
            add_row "$var" "$default" "$comment"
        fi
    done < "$ENV_FILE"
}

# Generate the documentation
echo "Generating documentation from $ENV_FILE..."
parse_env_file
echo "Documentation generated at $OUTPUT_FILE"
