#!/bin/sh

set -e

# Install dependencies
apk add --no-cache curl unzip gosu tini tzdata bash gcompat libc6-compat libstdc++

# Create symlink for consistent tini path
ln -sf /sbin/tini /usr/bin/tini
