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
TARBALL="${INSTALL_BASE}/fx.tar.xz"
BUILD_FILE="${INSTALL_BASE}/.fivem_build"
SHIPPED_BUILD="7290"

# 🔍 Show pre-install structure
echo "[*] File system layout at install start:"
command -v tree >/dev/null && tree -a -L 3 "${INSTALL_BASE}" || ls -R "${INSTALL_BASE}"
echo ""

# 🚨 Check if FXServer already exists
if [[ -f "$FXSERVER_BIN" ]]; then
  echo "[✔] FXServer already exists. Skipping static install."
  exit 0
fi

echo "[!] FXServer binary not found at $FXSERVER_BIN"

# 📦 Ensure fx.tar.xz is present
if [[ ! -f "$TARBALL" ]]; then
  echo "[-] fx.tar.xz not found at: $TARBALL"
  echo "[-] This container is missing its shipped FiveM build. Aborting."
  exit 1
fi

echo "[*] Extracting fx.tar.xz into $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

tar -xf "$TARBALL"
rm -f "$TARBALL"

# 📦 Unpack nested inner fx.tar.xz if needed
if [[ -f fx.tar.xz ]]; then
  echo "[!] Found nested fx.tar.xz — extracting inner archive..."
  tar -xf fx.tar.xz
  rm -f fx.tar.xz
fi

# 🧼 Flatten alpine layout if shipped
if [[ -d ./alpine/opt/cfx-server ]]; then
  echo "[!] Detected alpine structure — flattening contents..."
  cp -a ./alpine/opt/cfx-server/. ./ || true
  rm -rf ./alpine
fi

# ✅ Check FXServer result
if [[ -f "$FXSERVER_BIN" ]]; then
  echo "[✔] FXServer binary installed successfully."
  echo "$SHIPPED_BUILD" > "$BUILD_FILE"
  chmod +x "$FXSERVER_BIN"
else
  echo ""
  echo "=================================================="
  echo "[-] ERROR: FXServer not found after extraction"
  echo "=================================================="
  exit 1
fi

# 📄 Copy server.cfg if user dropped it into /home/container
cd "$INSTALL_BASE"
if [[ -f "./server.cfg" ]]; then
  echo "[*] Copying server.cfg to ${INSTALL_DIR}/"
  cp ./server.cfg "${INSTALL_DIR}/server.cfg"
  echo "[+] server.cfg copied successfully."
else
  echo "[!] Warning: server.cfg is missing in /home/container"
fi

# 📦 Post-install structure view
echo ""
echo "[*] File system layout after install:"
command -v tree >/dev/null && tree -a -L 3 "${INSTALL_BASE}" || ls -R "${INSTALL_BASE}"

echo ""
echo "=========================================="
echo "   [✔] DMS FiveM Installation Completed   "
echo "=========================================="
echo "   Build: $SHIPPED_BUILD"
echo "   Files extracted to: $INSTALL_DIR"
echo "   Thanks for using Darkmatter Servers!"
echo "   https://na.darkmatterservers.com"
echo ""
