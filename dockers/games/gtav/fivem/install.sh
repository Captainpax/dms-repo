#!/bin/bash
# DMS FiveM Install Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo "[*] Starting DMS FiveM installation..."

# Set sane defaults
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${DOWNLOAD_URL:-}"

# Create necessary directories
echo "[*] Preparing server directory structure..."
mkdir -p /home/container/opt/cfx-server
mkdir -p /home/container/resources
mkdir -p /home/container/logs
mkdir -p /home/container/cache

# Fetch artifact info
echo "[*] Fetching FiveM artifact metadata..."
RELEASE_PAGE=$(curl -sfSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sfSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

# Pick download link
if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
elif [[ "$FIVEM_VERSION" == "latest" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.latest_download')
else
    VERSION_LINK=$(echo "$RELEASE_PAGE" | grep -Eo '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION" || true)
    if [[ -z "$VERSION_LINK" ]]; then
        echo "[!] Invalid version '${FIVEM_VERSION}'. Falling back to recommended."
        DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
    else
        DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK}"
    fi
fi

# Manual override
if [[ -n "$FIVEM_DL_URL" ]]; then
    echo "[*] Manual override detected for download URL."
    DOWNLOAD_LINK="$FIVEM_DL_URL"
fi

# Download and extract
echo "[*] Downloading FiveM server artifact..."
cd /home/container/opt/cfx-server
curl -sfSL "$DOWNLOAD_LINK" -o "fivem.tar.xz"
tar -xf "fivem.tar.xz"
rm -f "fivem.tar.xz"

# Check for nested fx.tar.xz
if [[ -f fx.tar.xz ]]; then
    echo "[*] Nested fx.tar.xz found, extracting inner files..."
    tar -xf fx.tar.xz
    rm -f fx.tar.xz
fi

# Validate install
if [[ ! -f "./FXServer" ]]; then
    echo "[-] Error: FXServer binary still not found after extraction!"
    exit 1
fi

# Return to container root
cd /home/container

echo "[✔] DMS FiveM installation complete!"
