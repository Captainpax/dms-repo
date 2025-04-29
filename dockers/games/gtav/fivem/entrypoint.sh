#!/bin/bash
# DMS FiveM Entrypoint Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

cd /home/container || {
    echo "[-] Failed to change directory to /home/container"
    exit 1
}

# Auto-run installation if FXServer not found
if [[ ! -f "/home/container/opt/cfx-server/FXServer" ]]; then
    echo "[!] FXServer binary not found. Running installation script..."
    bash "./install.sh"
    sleep 2
fi

# Set a default safe startup command if STARTUP is empty
STARTUP="${STARTUP:-bash}"

# Replace all {{VAR}} with ${VAR} to allow environment variable expansion
MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

echo "[*] Preparing to start container with command:"
echo ":/home/container$ ${MODIFIED_STARTUP}"

# If txAdmin is enabled, print txAdmin panel URL
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "")

    if [[ -z "$PUBLIC_IP" ]]; then
        echo "[!] Warning: Could not detect external public IP address."
        PUBLIC_IP="127.0.0.1"
    fi

    PROTOCOL="http"
    echo "[+] txAdmin panel should be available at: ${PROTOCOL}://${PUBLIC_IP}:${TXADMIN_PORT}"
else
    echo "[*] txAdmin is disabled."
fi

# Finally run the startup command
exec /bin/bash -c "${MODIFIED_STARTUP}"