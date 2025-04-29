#!/bin/bash
# DMS FiveM Entrypoint Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m"; CYAN="\033[1;36m"

cd /home/container || {
    echo -e "${RED}[-] Failed to change directory to /home/container${RESET}"
    exit 1
}

# Auto-run installation if FXServer binary missing
if [[ ! -f "/home/container/opt/cfx-server/FXServer" ]]; then
    echo -e "${YELLOW}[!] FXServer binary not found. Running installation script...${RESET}"
    bash "./install.sh" || {
        echo -e "${RED}[!] Initial install failed! Retrying once...${RESET}"
        sleep 3
        bash "./install.sh" || {
            echo -e "${RED}[-] Install failed again. Aborting startup.${RESET}"
            exit 1
        }
    }
    sleep 2
else
    echo -e "${GREEN}[+] FXServer binary detected. Skipping install.${RESET}"
fi

# Show installed FiveM build if known
if [[ -f "/home/container/.fivem_build" ]]; then
    BUILD_VERSION=$(cat /home/container/.fivem_build)
    echo -e "${CYAN}[*] Installed FiveM Build: ${BOLD}${BUILD_VERSION}${RESET}"
fi

# -----------------------------
# Build the startup command carefully with strict safety
# -----------------------------

STARTUP_CMD="./opt/cfx-server/FXServer +exec server.cfg"
STARTUP_CMD+=" +set sv_licenseKey \"${FIVEM_LICENSE:?FIVEM_LICENSE environment variable not set}\""
STARTUP_CMD+=" +set steam_webApiKey \"${STEAM_WEBAPIKEY:?STEAM_WEBAPIKEY environment variable not set}\""
STARTUP_CMD+=" +set onesync \"${ONESYNC_STATE:?ONESYNC_STATE environment variable not set}\""

if [[ -n "${GAME_BUILD:-}" ]]; then
    STARTUP_CMD+=" +set sv_enforceGameBuild ${GAME_BUILD}"
fi

STARTUP_CMD+=" +sets sv_projectName \"${PROJECT_NAME:-Darkmatter Server}\""
STARTUP_CMD+=" +sets sv_projectDesc \"${PROJECT_DESCRIPTION:-Welcome to Darkmatter!}\""
STARTUP_CMD+=" +set txAdminPort ${TXADMIN_PORT:-40120}"
STARTUP_CMD+=" +set txAdminEnabled ${TXADMIN_ENABLE:-1}"
STARTUP_CMD+=" +set sv_endpoint_add_tcp \"0.0.0.0:${FIVEM_PORT:-30120}\""
STARTUP_CMD+=" +set sv_endpoint_add_udp \"0.0.0.0:${FIVEM_PORT:-30120}\""

echo -e "${BLUE}[*] Preparing to start container with command:${RESET}"
echo -e "${BOLD}:/home/container$ ${STARTUP_CMD}${RESET}"

# If txAdmin is enabled, show txAdmin URL
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "127.0.0.1")
    PROTOCOL="http"
    echo -e "${GREEN}[+] txAdmin should be available at: ${PROTOCOL}://${PUBLIC_IP}:${TXADMIN_PORT}${RESET}"
else
    echo -e "${YELLOW}[*] txAdmin is disabled.${RESET}"
fi

# Mini runtime health checks
if [[ ! -f "./server.cfg" ]]; then
    echo -e "${RED}[!] server.cfg not found! Startup may fail.${RESET}"
fi

if [[ ! -d "./resources" ]]; then
    echo -e "${YELLOW}[!] Warning: No /resources folder detected.${RESET}"
fi

# Finally launch it properly
exec /bin/bash -c "${STARTUP_CMD}"