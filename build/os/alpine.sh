#!/bin/sh

set -e

# Add hytale user
addgroup --gid 1000 hytale
adduser -Ss /bin/false -u 1000 -G hytale -h "$HYTALE_HOME" hytale

# Install dependencies
apk add --no-cache curl unzip gosu tini tzdata bash gcompat libc6-compat libstdc++

# Create symlink for consistent tini path
ln -sf /sbin/tini /usr/bin/tini
