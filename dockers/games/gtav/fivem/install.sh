#!/bin/bash
# DMS FiveM Install Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo ""
echo "=========================================="
echo "    [*] Starting DMS FiveM Installation    "
echo "=========================================="
echo ""

# Set safe defaults
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${DOWNLOAD_URL:-}"
RETRY_MAX=3
RETRY_DELAY=5

# Make sure required tools exist
if ! command -v curl &> /dev/null; then
    echo "[!] curl is not installed. Cannot continue."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "[*] jq not found, installing..."
    apt-get update && apt-get install -y jq || {
        echo "[!] Failed to install jq. Aborting."
        exit 1
    }
fi

# Prepare folder structure
echo "[*] Preparing server directory structure..."
mkdir -p /home/container/opt/cfx-server /home/container/resources /home/container/logs /home/container/cache
echo "[+] Directories ensured."

# Fetch artifact metadata
echo "[*] Fetching FiveM artifact metadata..."
RELEASE_PAGE=$(curl -fsSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/ || true)
CHANGELOGS_PAGE=$(curl -fsSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server || true)

if [[ -z "$CHANGELOGS_PAGE" ]]; then
    echo "[!] Failed to fetch changelog metadata from FiveM. Check network."
    exit 1
fi

echo "[+] Metadata fetched."

# Determine which artifact to download
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

if [[ -z "$DOWNLOAD_LINK" ]] || [[ "$DOWNLOAD_LINK" == "null" ]]; then
    echo "[!] Failed to determine download link. Aborting."
    exit 1
fi

# Show download link
echo "[*] Final Download URL:"
echo "    $DOWNLOAD_LINK"

# Download & Extract FXServer
cd /home/container/opt/cfx-server || exit 1

for ((attempt=1; attempt<=RETRY_MAX; attempt++)); do
    echo "[*] Attempt ${attempt} to download and extract artifact..."

    rm -rf /home/container/opt/cfx-server/*
    curl -fsSL "$DOWNLOAD_LINK" -o fivem.tar.xz || {
        echo "[!] Download failed. Retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
        continue
    }
    tar -xf fivem.tar.xz
    rm -f fivem.tar.xz

    echo "[*] Files after extraction:"
    find . -type f || true

    # Handle nested fx.tar.xz if present
    if [[ -f fx.tar.xz ]]; then
        echo "[!] Nested fx.tar.xz found. Extracting..."
        tar -xf fx.tar.xz
        rm -f fx.tar.xz
        echo "[+] Nested extraction complete."
    fi

    # Flatten if alpine layout detected
    if [[ -d "./alpine/opt/cfx-server" ]]; then
        echo "[!] Detected nested alpine folder. Flattening structure..."
        cp -a ./alpine/opt/cfx-server/. ./
        rm -rf ./alpine
        echo "[+] Structure flattened."
    fi

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

# Post Install
cd /home/container
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
