#!/bin/bash
# DMS FiveM Static Installer - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

echo ""
echo "=========================================="
echo "    [*] Starting DMS FiveM Installer       "
echo "=========================================="
echo ""

INSTALL_BASE="/home/container"
INSTALL_DIR="${INSTALL_BASE}/opt/cfx-server"
FXSERVER_BIN="${INSTALL_DIR}/FXServer"
BUILD_NUM="7290"
ARCHIVE_NAME="fx.tar.xz"

echo "[*] File system layout at install start:"
find "${INSTALL_BASE}" -type d -print | sed 's|^|  |'

# Already installed?
if [[ -f "$FXSERVER_BIN" ]]; then
  echo "[✔] FXServer binary already exists at $FXSERVER_BIN"
  exit 0
fi

# Ensure fx.tar.xz exists
if [[ ! -f "${INSTALL_BASE}/${ARCHIVE_NAME}" ]]; then
  echo "[-] This container is missing ${ARCHIVE_NAME}. Aborting."
  exit 1
fi

echo "[*] FXServer binary not found at ${FXSERVER_BIN}"
echo "[*] Extracting ${ARCHIVE_NAME} into ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

tar -xf "${INSTALL_BASE}/${ARCHIVE_NAME}"

# Flatten alpine structure if needed
if [[ -d "./alpine/opt/cfx-server" ]]; then
  echo "[!] Detected alpine structure — flattening contents..."
  cp -a ./alpine/opt/cfx-server/. ./ || true
  rm -rf ./alpine
fi

# Confirm binary
if [[ -f "./FXServer" ]]; then
  chmod +x ./FXServer
  echo "$BUILD_NUM" > "${INSTALL_BASE}/.fivem_build"
  echo "[✔] FXServer binary installed successfully."
else
  echo "[-] FXServer binary not found after extraction. Aborting."
  exit 1
fi

# Render and deploy server.cfg
TEMPLATE="${INSTALL_BASE}/server.cfg"
TARGET="${INSTALL_DIR}/server.cfg"

if [[ -f "$TEMPLATE" ]]; then
  echo "[*] Rendering server.cfg template with environment variables..."

  export FIVEM_PORT SERVER_HOSTNAME PROJECT_NAME PROJECT_DESCRIPTION \
         MAX_PLAYERS FIVEM_LICENSE STEAM_WEBAPIKEY RCON_PASSWORD \
         GAME_BUILD ONESYNC_STATE

  envsubst < "$TEMPLATE" > "$TARGET"
  echo "[+] server.cfg rendered and deployed."
else
  echo "[!] Warning: server.cfg template not found at ${TEMPLATE}"
fi

# Final structure check
echo ""
echo "[*] File system layout after install:"
find "${INSTALL_BASE}" -type d -print | sed 's|^|  |'

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo "   Build: ${BUILD_NUM}"
echo "   Files extracted to: ${INSTALL_DIR}"
echo "   Thanks for using Darkmatter Servers!"
echo "   https://na.darkmatterservers.com"
echo ""