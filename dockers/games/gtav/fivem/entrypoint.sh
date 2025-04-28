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

# If txAdmin is enabled, print the txAdmin panel URL with best practices
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    # Try to detect external IP (safe fallback)
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "0.0.0.0")

    # Warn if no valid IP
    if [[ "$PUBLIC_IP" == "0.0.0.0" ]]; then
        echo "[!] Warning: Could not detect external IP. Your txAdmin panel might not be reachable externally."
    fi

    # Assume HTTP, unless you configure HTTPS manually later
    PROTOCOL="http"

    # Check for common proxy env vars (stub for future use)
    if [[ -n "${CF_CONNECTING_IP:-}" ]]; then
        echo "[*] Cloudflare detected. You might need extra proxy config for txAdmin HTTPS."
    fi

    echo "[+] txAdmin panel should be available at: ${PROTOCOL}://${PUBLIC_IP}:${TXADMIN_PORT}"
fi

# Run the final command
exec /bin/bash -c "${MODIFIED_STARTUP}"
