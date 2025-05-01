#!/bin/bash
# DMS FiveM Smart Install/Update Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo ""
echo "=========================================="
echo "    [*] Starting DMS FiveM Installer       "
echo "=========================================="
echo ""

# Constants and Environment
INSTALL_BASE="/home/container"
INSTALL_DIR="${INSTALL_BASE}/opt/cfx-server"
FXSERVER_BIN="${INSTALL_DIR}/FXServer"
BUILD_FILE="${INSTALL_BASE}/.fivem_build"
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${FIVEM_DL_URL:-}"
RETRY_MAX=3
RETRY_DELAY=5

fetch_recommended_build() {
    curl -s https://changelogs-live.fivem.net/api/changelog/versions/linux/server | jq -r '.recommended'
}

fetch_recommended_download() {
    curl -s https://changelogs-live.fivem.net/api/changelog/versions/linux/server | jq -r '.recommended_download'
}

download_and_install_fivem() {
    echo "[*] Creating necessary directories..."
    mkdir -p "${INSTALL_DIR}" "${INSTALL_BASE}/resources" "${INSTALL_BASE}/logs" "${INSTALL_BASE}/cache"
    cd "${INSTALL_DIR}" || exit 1

    echo "[*] Determining download source..."

    if [[ -n "$FIVEM_DL_URL" ]]; then
        DOWNLOAD_LINK="$FIVEM_DL_URL"
        BUILD_NUM="manual"
        echo "[!] Manual download override used."
    else
        CHANGELOGS=$(curl -fsSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

        if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
            DOWNLOAD_LINK=$(echo "$CHANGELOGS" | jq -r '.recommended_download')
            BUILD_NUM=$(fetch_recommended_build)
            echo "[+] Using recommended build: $BUILD_NUM"
        elif [[ "$FIVEM_VERSION" == "latest" ]]; then
            DOWNLOAD_LINK=$(echo "$CHANGELOGS" | jq -r '.latest_download')
            BUILD_NUM="latest"
            echo "[+] Using latest build"
        else
            RELEASES=$(curl -fsSL https://runtime.fivem.net/artifacts/fivem/build_linux/master/)
            MATCH=$(echo "$RELEASES" | grep -oE '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION" || true)
            if [[ -n "$MATCH" ]]; then
                DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_linux/master/${MATCH}"
                BUILD_NUM="$FIVEM_VERSION"
                echo "[+] Using custom build: $BUILD_NUM"
            else
                echo "[!] Invalid version '${FIVEM_VERSION}' — falling back to recommended."
                DOWNLOAD_LINK=$(fetch_recommended_download)
                BUILD_NUM=$(fetch_recommended_build)
            fi
        fi
    fi

    if [[ -z "$DOWNLOAD_LINK" || "$DOWNLOAD_LINK" == "null" ]]; then
        echo "[!] Failed to determine download URL. Aborting."
        exit 1
    fi

    echo "[*] Downloading artifact:"
    echo "    $DOWNLOAD_LINK"

    for (( attempt=1; attempt<=RETRY_MAX; attempt++ )); do
        echo "[*] Attempt $attempt of $RETRY_MAX..."

        rm -rf "${INSTALL_DIR:?}/"*
        curl -fsSL "$DOWNLOAD_LINK" -o fivem.tar.xz || {
            echo "[!] Download failed. Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
            continue
        }

        tar -xf fivem.tar.xz
        rm -f fivem.tar.xz

        echo "[*] Extracted files:"
        find . -type f || true

        if [[ -f fx.tar.xz ]]; then
            echo "[!] Found fx.tar.xz, extracting nested archive..."
            tar -xf fx.tar.xz
            rm -f fx.tar.xz
        fi

        if [[ -d "./alpine/opt/cfx-server" ]]; then
            echo "[!] Detected nested alpine structure, flattening..."
            cp -a ./alpine/opt/cfx-server/. ./ || true
            rm -rf ./alpine
        fi

        if [[ -f "./FXServer" ]]; then
            echo "[✔] FXServer binary installed."
            echo "${BUILD_NUM}" > "${BUILD_FILE}"
            chmod +x "./FXServer"
            break
        else
            echo "[!] FXServer not found. Retrying..."
            sleep $RETRY_DELAY
        fi

        if [[ $attempt -eq $RETRY_MAX ]]; then
            echo ""
            echo "=================================================="
            echo "[-] ERROR: FXServer install failed after $RETRY_MAX attempts"
            echo "=================================================="
            exit 1
        fi
    done

    cd "$INSTALL_BASE"

    # Copy server.cfg if present
    if [[ -f "./server.cfg" ]]; then
        echo "[*] Copying server.cfg to ${INSTALL_DIR}/"
        cp ./server.cfg "${INSTALL_DIR}/server.cfg"
        echo "[+] server.cfg copied successfully."
    else
        echo "[!] Warning: server.cfg not found in working directory."
    fi
}

# ----------------------------------
# Begin Installation
# ----------------------------------

if [[ -f "$FXSERVER_BIN" ]]; then
    echo "[✔] FXServer already installed. Checking version..."
    CURRENT_BUILD=$(cat "$BUILD_FILE" 2>/dev/null || echo "unknown")
    LATEST_BUILD=$(fetch_recommended_build)
    echo "[*] Current: $CURRENT_BUILD | Latest: $LATEST_BUILD"

    if [[ "$CURRENT_BUILD" != "$LATEST_BUILD" ]]; then
        echo "[!] Version mismatch — updating..."
        download_and_install_fivem
    else
        echo "[+] FXServer is up to date."
    fi
else
    echo "[!] No FXServer binary found — fresh install..."
    download_and_install_fivem
fi

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo "   Thanks for using Darkmatter Servers!"
echo "   https://na.darkmatterservers.com"
echo ""
