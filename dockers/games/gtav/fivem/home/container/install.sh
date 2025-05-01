#!/bin/bash
# DMS FiveM Static Installer - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

# Styling
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

INSTALL_BASE="/home/container"
INSTALL_DIR="${INSTALL_BASE}/opt/cfx-server"
FXSERVER_BIN="${INSTALL_DIR}/FXServer"
BUILD_NUM="7290"

echo ""
echo -e "${CYAN}==========================================${RESET}"
echo -e "${CYAN}    [*] Starting DMS FiveM Installer       ${RESET}"
echo -e "${CYAN}==========================================${RESET}"
echo ""

# 🗂️ Debug: directory tree before install
echo -e "${BLUE}[*] File system layout at install start:${RESET}"
find "$INSTALL_BASE" -type d -print | sed 's|^|  |'

# 🧠 Binary validation
if [[ -x "$FXSERVER_BIN" ]]; then
  echo -e "${GREEN}[✔] FXServer binary detected at: ${FXSERVER_BIN}${RESET}"
else
  echo -e "${RED}[-] FXServer binary not found or not executable at ${FXSERVER_BIN}${RESET}"
  echo -e "${RED}[-] This container build may be corrupted or incomplete. Aborting.${RESET}"
  exit 1
fi

# 🏷️ Record build number
echo "$BUILD_NUM" > "${INSTALL_BASE}/.fivem_build"

# 🧾 Render server.cfg with env vars
TEMPLATE="${INSTALL_BASE}/server.cfg"
TARGET="${INSTALL_DIR}/server.cfg"

if [[ -f "$TEMPLATE" ]]; then
  echo -e "${BLUE}[*] Rendering server.cfg template with environment variables...${RESET}"

  export FIVEM_PORT SERVER_HOSTNAME PROJECT_NAME PROJECT_DESCRIPTION \
         MAX_PLAYERS FIVEM_LICENSE STEAM_WEBAPIKEY RCON_PASSWORD \
         GAME_BUILD ONESYNC_STATE

  envsubst < "$TEMPLATE" > "$TARGET"
  echo -e "${GREEN}[+] server.cfg rendered and deployed to ${TARGET}${RESET}"
else
  echo -e "${YELLOW}[!] Warning: server.cfg template not found at ${TEMPLATE}${RESET}"
fi

# 📂 Final structure check
echo ""
echo -e "${BLUE}[*] File system layout after install:${RESET}"
find "$INSTALL_BASE" -type d -print | sed 's|^|  |'

# ✅ Complete
echo ""
echo -e "${GREEN}==========================================${RESET}"
echo -e "${GREEN}   [✔] DMS FiveM Installation Completed   ${RESET}"
echo -e "${GREEN}==========================================${RESET}"
echo -e "${CYAN}   Build: ${BOLD}${BUILD_NUM}${RESET}"
echo -e "${CYAN}   Files verified in: ${BOLD}${INSTALL_DIR}${RESET}"
echo -e "${CYAN}   Thanks for using ${BOLD}Darkmatter Servers!${RESET}"
echo -e "${CYAN}   https://na.darkmatterservers.com${RESET}"
echo ""
