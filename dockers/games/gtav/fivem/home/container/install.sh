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

# Debug: print initial directory tree
echo "[*] File system layout at install start:"
find "${INSTALL_BASE}" -type d -print | sed 's|^|  |'

# Binary presence check (since extraction is done at build)
if [[ -f "$FXSERVER_BIN" ]]; then
  echo "[✔] FXServer binary detected at: $FXSERVER_BIN"
else
  echo "[-] FXServer binary not found at ${FXSERVER_BIN}"
  echo "[-] This container build may be corrupted or incomplete. Aborting."
  exit 1
fi

# Record build number
echo "${BUILD_NUM}" > "${INSTALL_BASE}/.fivem_build"

# Process server.cfg template
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

# Final structure display
echo ""
echo "[*] File system layout after install:"
find "${INSTALL_BASE}" -type d -print | sed 's|^|  |'

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo "   Build: ${BUILD_NUM}"
echo "   Files verified in: ${INSTALL_DIR}"
echo "   Thanks for using Darkmatter Servers!"
echo "   https://na.darkmatterservers.com"
echo ""
