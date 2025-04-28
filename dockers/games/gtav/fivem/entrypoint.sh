#!/bin/bash
set -e

cd /home/container || exit 1

# If STARTUP is empty, set a default safe command
STARTUP="${STARTUP:-bash}"

# Replace {{VAR}} with ${VAR} in startup string
MODIFIED_STARTUP=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo ":/home/container$ $MODIFIED_STARTUP"

# Execute the startup command
eval "$MODIFIED_STARTUP"