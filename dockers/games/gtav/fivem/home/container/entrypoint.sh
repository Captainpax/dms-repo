#!/bin/bash
# DMS FiveM Entrypoint Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

# Styling
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

cd /home/container || {
    echo -e "${RED}[-] Failed to change directory to /home/container${RESET}"
    exit 1
}

# Ensure FXServer is installed
if [[ ! -f "./opt/cfx-server/FXServer" ]]; then
    echo -e "${YELLOW}[!] FXServer binary not found. Running installer...${RESET}"
    bash "./install.sh" || {
        echo -e "${RED}[!] Install failed. Retrying in 3 seconds...${RESET}"
        sleep 3
        bash "./install.sh" || {
            echo -e "${RED}[-] Install failed again. Aborting.${RESET}"
            exit 1
        }
    }
    sleep 1
else
    echo -e "${GREEN}[+] FXServer binary found. Skipping install.${RESET}"
fi

# Display build info
if [[ -f "./.fivem_build" ]]; then
    BUILD_VERSION=$(< ./.fivem_build)
    echo -e "${CYAN}[*] Installed FiveM Build: ${BOLD}${BUILD_VERSION}${RESET}"
fi

# ----------------------------------
# Build startup command
# ----------------------------------

STARTUP_CMD="./opt/cfx-server/FXServer +exec server.cfg"

STARTUP_CMD+=" +set sv_licenseKey \"${FIVEM_LICENSE:?Missing FIVEM_LICENSE env variable}\""
STARTUP_CMD+=" +set steam_webApiKey \"${STEAM_WEBAPIKEY:-changeme}\""
STARTUP_CMD+=" +set onesync \"${ONESYNC_STATE:-on}\""

[[ -n "${GAME_BUILD:-}" ]] && STARTUP_CMD+=" +set sv_enforceGameBuild ${GAME_BUILD}"

STARTUP_CMD+=" +sets sv_projectName \"${PROJECT_NAME:-Darkmatter Server}\""
STARTUP_CMD+=" +sets sv_projectDesc \"${PROJECT_DESCRIPTION:-Welcome to Darkmatter!}\""
STARTUP_CMD+=" +set txAdminPort ${TXADMIN_PORT:-40120}"
STARTUP_CMD+=" +set txAdminEnabled ${TXADMIN_ENABLE:-1}"
STARTUP_CMD+=" +set sv_endpoint_add_tcp \"0.0.0.0:${FIVEM_PORT:-30120}\""
STARTUP_CMD+=" +set sv_endpoint_add_udp \"0.0.0.0:${FIVEM_PORT:-30120}\""

# Log final command
echo -e "${BLUE}[*] Launching with command:${RESET}"
echo -e "${BOLD}:/home/container$ ${STARTUP_CMD}${RESET}"

# TXAdmin info
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "127.0.0.1")
    echo -e "${GREEN}[+] txAdmin available at: http://${PUBLIC_IP}:${TXADMIN_PORT:-40120}${RESET}"
else
    echo -e "${YELLOW}[*] txAdmin is disabled.${RESET}"
fi

# Basic checks
[[ ! -f "./server.cfg" ]] && echo -e "${RED}[!] Warning: server.cfg missing!${RESET}"
[[ ! -d "./resources" ]] && echo -e "${YELLOW}[!] No /resources/ folder detected.${RESET}"

# Launch FXServer
exec /bin/bash -c "${STARTUP_CMD}"