#!/bin/sh

set -e

# Install dependencies
apt-get update && apt-get install -y \
    curl unzip gosu tini tzdata && \
    rm -rf /var/lib/apt/lists/*
