#!/bin/bash
# DMS FiveM Smart Install/Update Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo ""
echo "=========================================="
echo "    [*] Starting DMS FiveM Installer       "
echo "=========================================="
echo ""

# Settings
FIVEM_VERSION="${FIVEM_VERSION:-recommended}"
FIVEM_DL_URL="${FIVEM_DL_URL:-}"
RETRY_MAX=3
RETRY_DELAY=5
INSTALL_DIR="/home/container/opt/cfx-server"
FXSERVER_BIN="$INSTALL_DIR/FXServer"
BUILD_FILE="/home/container/.fivem_build"

# Function to fetch recommended build number
fetch_recommended_build() {
    curl -s https://changelogs-live.fivem.net/api/changelog/versions/linux/server | jq -r '.recommended'
}

# Function to fetch recommended download URL
fetch_recommended_download() {
    curl -s https://changelogs-live.fivem.net/api/changelog/versions/linux/server | jq -r '.recommended_download'
}

# Function to download and install FiveM
download_and_install_fivem() {
    echo "[*] Preparing installation directories..."
    mkdir -p "${INSTALL_DIR}" /home/container/resources /home/container/logs /home/container/cache
    cd "${INSTALL_DIR}" || exit 1

    echo "[*] Determining artifact download URL..."

    if [[ -n "$FIVEM_DL_URL" ]]; then
        # Manual override (Nextcloud or custom link)
        DOWNLOAD_LINK="$FIVEM_DL_URL"
        BUILD_NUM="manual"
        echo "[!] Manual override download URL detected."
    else
        # Automatic fetch
        CHANGELOGS_PAGE=$(curl -fsSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

        if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
            DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.recommended_download')
            BUILD_NUM=$(fetch_recommended_build)
            echo "[+] Selected recommended build: ${BUILD_NUM}"
        elif [[ "$FIVEM_VERSION" == "latest" ]]; then
            DOWNLOAD_LINK=$(echo "$CHANGELOGS_PAGE" | jq -r '.latest_download')
            BUILD_NUM="latest"
            echo "[+] Selected latest build."
        else
            RELEASE_PAGE=$(curl -fsSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
            VERSION_LINK=$(echo "$RELEASE_PAGE" | grep -oE '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION" || true)
            if [[ -n "$VERSION_LINK" ]]; then
                DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK}"
                BUILD_NUM="$FIVEM_VERSION"
                echo "[+] Selected custom build: ${BUILD_NUM}"
            else
                echo "[!] Invalid build '${FIVEM_VERSION}' given, falling back to recommended."
                DOWNLOAD_LINK=$(fetch_recommended_download)
                BUILD_NUM=$(fetch_recommended_build)
            fi
        fi
    fi

    if [[ -z "$DOWNLOAD_LINK" ]] || [[ "$DOWNLOAD_LINK" == "null" ]]; then
        echo "[!] Could not determine valid download link. Aborting install."
        exit 1
    fi

    echo "[*] Downloading artifact from:"
    echo "    ${DOWNLOAD_LINK}"

    # Download and extract with retries
    for (( attempt=1; attempt<=RETRY_MAX; attempt++ )); do
        echo "[*] Attempt ${attempt} to download and extract FiveM server..."

        rm -rf "${INSTALL_DIR:?}"/*
        curl -fsSL "$DOWNLOAD_LINK" -o fivem.tar.xz || {
            echo "[!] Download failed. Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
            continue
        }
        tar -xf fivem.tar.xz
        rm -f fivem.tar.xz

        echo "[*] Files extracted:"
        find . -type f || true

        if [[ -f fx.tar.xz ]]; then
            echo "[!] Nested fx.tar.xz found inside, extracting..."
            tar -xf fx.tar.xz
            rm -f fx.tar.xz
            echo "[+] Nested extraction complete."
        fi

        if [[ -d "./alpine/opt/cfx-server" ]]; then
            echo "[!] Alpine nested structure detected. Flattening..."
            cp -a ./alpine/opt/cfx-server/. ./ || true
            rm -rf ./alpine
            echo "[+] Flatten complete."
        fi

        if [[ -f "./FXServer" ]]; then
            echo "[✔] FXServer binary successfully installed."
            echo "${BUILD_NUM}" > "${BUILD_FILE}"
            chmod +x "./FXServer"
            break
        else
            echo "[!] FXServer binary not found. Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi

        if [[ $attempt -eq $RETRY_MAX ]]; then
            echo ""
            echo "=================================================="
            echo "[-] ERROR: FXServer not found after ${RETRY_MAX} attempts."
            echo "[-] Installation failed. Aborting."
            echo "=================================================="
            exit 1
        fi
    done

    cd /home/container
}

# Main logic
if [[ -f "$FXSERVER_BIN" ]]; then
    echo "[✔] FXServer binary exists. Checking version..."

    CURRENT_BUILD=$(cat "$BUILD_FILE" 2>/dev/null || echo "unknown")
    LATEST_BUILD=$(fetch_recommended_build)

    echo "[*] Current installed build: ${CURRENT_BUILD}"
    echo "[*] Latest recommended build: ${LATEST_BUILD}"

    if [[ "$CURRENT_BUILD" != "$LATEST_BUILD" ]]; then
        echo "[!] Version mismatch detected. Installing latest build..."
        download_and_install_fivem
    else
        echo "[+] FXServer is already up-to-date."
    fi
else
    echo "[!] FXServer binary missing. Fresh install starting..."
    download_and_install_fivem
fi

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo ""
echo "    Thank you for choosing Darkmatter Servers!"
echo "   Main Site: https://antimatterzone.net"
echo "   Hosting:   https://na.darkmatterservers.com"
echo ""