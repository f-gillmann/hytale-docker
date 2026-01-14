#!/bin/sh

set -e

# Remove default ubuntu user if it exists
if id ubuntu > /dev/null 2>&1; then
  deluser ubuntu
fi

# Add hytale user
addgroup --gid 1000 hytale
adduser --system --shell /bin/false --uid 1000 --ingroup hytale --home "$HYTALE_HOME" hytale

# Install dependencies
apt-get update && apt-get install -y \
    curl unzip gosu tini tzdata && \
    rm -rf /var/lib/apt/lists/*
