#!/bin/sh

set -e

# Add hytale user
addgroup --gid 1000 hytale
adduser -Ss /bin/false -u 1000 -G hytale -h "$HYTALE_HOME" hytale
