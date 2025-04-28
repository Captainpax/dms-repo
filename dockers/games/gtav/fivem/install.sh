#!/bin/bash
# DMS FiveM Install Script for Pterodactyl Panel - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo "[*] Starting DMS FiveM installation..."

# Set variables with sane defaults
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${DOWNLOAD_URL:-}"

# Create required server directories
echo "[*] Preparing server directory structure..."
mkdir -p /home/container/opt/cfx-server
mkdir -p /home/container/resources
mkdir -p /home/container/logs
mkdir -p /home/container/cache

# Install necessary packages
echo "[*] Installing required system packages..."
apt update
apt install -y --no-install-recommends \
    curl git unzip xz-utils file jq ca-certificates \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Fetch FiveM artifact metadata
echo "[*] Fetching FiveM artifact metadata..."
RELEASE_PAGE=$(curl -sfSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sfSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

# Determine correct artifact download URL
if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
elif [[ "$FIVEM_VERSION" == "latest" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.latest_download')
else
    VERSION_LINK=$(echo "$RELEASE_PAGE" | grep -Eo '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION" || true)
    if [[ -z "$VERSION_LINK" ]]; then
        echo "[!] Invalid specified version '${FIVEM_VERSION}'. Falling back to recommended version."
        DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
    else
        DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK}"
    fi
fi

# Allow full manual override
if [[ -n "$FIVEM_DL_URL" ]]; then
    echo "[*] Manual override detected. Using provided DOWNLOAD_URL."
    DOWNLOAD_LINK="$FIVEM_DL_URL"
fi

# Download and extract FiveM server
echo "[*] Downloading and extracting FiveM server artifact..."
cd /home/container/opt/cfx-server
curl -sfSL "$DOWNLOAD_LINK" -o fivem.tar.xz
tar -xf fivem.tar.xz
rm -f fivem.tar.xz

# Return to container root
cd /home/container

# Check if FXServer binary exists
if [[ ! -f "./opt/cfx-server/FXServer" ]]; then
    echo "[-] Error: FXServer binary not found after extraction!"
    exit 1
fi

# Note: server.cfg is now bundled inside Docker image (no live download needed).

echo "[✔] DMS FiveM installation complete!"
