#!/bin/bash
# DMS FiveM Install Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo ""
echo "=========================================="
echo "    [*] Starting DMS FiveM Installation    "
echo "=========================================="
echo ""

# Set sane defaults
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${DOWNLOAD_URL:-}"
RETRY_MAX=3
RETRY_DELAY=5

# Create necessary directories
echo "[*] Preparing server directory structure..."
mkdir -p /home/container/opt/cfx-server
mkdir -p /home/container/resources
mkdir -p /home/container/logs
mkdir -p /home/container/cache
echo "[+] Directories ensured."

# Fetch artifact info
echo "[*] Fetching FiveM artifact metadata..."
RELEASE_PAGE=$(curl -sfSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sfSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)
echo "[+] Metadata fetched."

# Determine download link
echo "[*] Determining download link..."
if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
    echo "[+] Selected recommended version."
elif [[ "$FIVEM_VERSION" == "latest" ]]; then
    DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.latest_download')
    echo "[+] Selected latest version."
else
    VERSION_LINK=$(echo "$RELEASE_PAGE" | grep -Eo '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION" || true)
    if [[ -z "$VERSION_LINK" ]]; then
        echo "[!] Invalid version '${FIVEM_VERSION}'. Falling back to recommended."
        DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
    else
        DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK}"
        echo "[+] Custom version selected: ${FIVEM_VERSION}"
    fi
fi

# Manual override
if [[ -n "$FIVEM_DL_URL" ]]; then
    echo "[!] Manual override detected for download URL."
    DOWNLOAD_LINK="$FIVEM_DL_URL"
fi

# Final download link info
echo "[*] Download URL:"
echo "    $DOWNLOAD_LINK"

# Download and extract with retries
cd /home/container/opt/cfx-server
for ((attempt=1; attempt<=RETRY_MAX; attempt++)); do
    echo "[*] Attempt ${attempt} to download and extract artifact..."

    rm -rf /home/container/opt/cfx-server/*
    curl -sfSL "$DOWNLOAD_LINK" -o "fivem.tar.xz" && \
    tar -xf "fivem.tar.xz" && \
    rm -f "fivem.tar.xz"

    echo "[*] Listing files after primary extraction:"
    find . -type f

    if [[ -f fx.tar.xz ]]; then
        echo "[!] Nested fx.tar.xz found, extracting..."
        tar -xf fx.tar.xz
        rm -f fx.tar.xz
        echo "[+] Nested extraction complete."
    fi

    echo "[*] Final files after nested extraction (if any):"
    find . -type f

    # Detect Alpine nested structure and fix
    if [[ -d "./alpine/opt/cfx-server" ]]; then
        echo "[!] Detected nested alpine folder. Flattening directory structure..."
        cp -a ./alpine/opt/cfx-server/. ./
        rm -rf ./alpine
        echo "[+] Structure flattened."
    fi

    # Validate if FXServer exists
    if [[ -f "./FXServer" ]]; then
        echo "[✔] FXServer binary found. Installation succeeded."
        break
    else
        echo "[!] FXServer binary not found. Retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    fi

    if [[ $attempt -eq $RETRY_MAX ]]; then
        echo ""
        echo "=================================================="
        echo "[-] ERROR: FXServer binary NOT found after ${RETRY_MAX} attempts."
        echo "[-] Installation failed."
        echo "=================================================="
        exit 1
    fi
done

# Return to container root
cd /home/container

# Make FXServer executable
chmod +x /home/container/opt/cfx-server/FXServer

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo ""
echo "    Thank you for choosing Darkmatter Servers!"
echo "   Main Site: https://antimatterzone.net"
echo "   Hosting:   https://na.darkmatterservers.com"
echo ""