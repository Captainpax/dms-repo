#!/bin/bash
cd /home/container || exit 1

# Echo evaluated startup command
MODIFIED_STARTUP=$(eval echo "$STARTUP" | sed 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Execute the startup command
exec ${MODIFIED_STARTUP}
