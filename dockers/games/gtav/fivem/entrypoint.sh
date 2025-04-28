#!/bin/bash
set -euo pipefail

cd /home/container || {
    echo "[-] Failed to change directory to /home/container"
    exit 1
}

# Set a default safe startup command if STARTUP is empty
STARTUP="${STARTUP:-bash}"

# Replace all {{VAR}} with ${VAR} to allow environment variable expansion
MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo "[*] Starting container with command:"
echo ":/home/container$ ${MODIFIED_STARTUP}"

# If txAdmin is enabled, print the txAdmin panel URL
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    echo "[+] txAdmin panel should be available at: http://\$(hostname -I | awk '{print \$1}'):${TXADMIN_PORT}"
fi

# Run the final startup command
exec /bin/bash -c "${MODIFIED_STARTUP}"
