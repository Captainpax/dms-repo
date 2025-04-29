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
# Create startup command manually
# -----------------------------

STARTUP_CMD=( "./opt/cfx-server/FXServer" "+exec" "server.cfg" )

# Add dynamic runtime args
[[ -n "${FIVEM_LICENSE:-}" ]] && STARTUP_CMD+=( "+set" "sv_licenseKey" "${FIVEM_LICENSE}" )
[[ -n "${STEAM_WEBAPIKEY:-}" ]] && STARTUP_CMD+=( "+set" "steam_webApiKey" "${STEAM_WEBAPIKEY}" )
[[ -n "${ONESYNC_STATE:-}" ]] && STARTUP_CMD+=( "+set" "onesync" "${ONESYNC_STATE}" )
[[ -n "${GAME_BUILD:-}" ]] && STARTUP_CMD+=( "+set" "sv_enforceGameBuild" "${GAME_BUILD}" )
[[ -n "${PROJECT_NAME:-}" ]] && STARTUP_CMD+=( "+sets" "sv_projectName" "${PROJECT_NAME}" )
[[ -n "${PROJECT_DESCRIPTION:-}" ]] && STARTUP_CMD+=( "+sets" "sv_projectDesc" "${PROJECT_DESCRIPTION}" )
[[ -n "${TXADMIN_PORT:-}" ]] && STARTUP_CMD+=( "+set" "txAdminPort" "${TXADMIN_PORT}" )
[[ -n "${TXADMIN_ENABLE:-}" ]] && STARTUP_CMD+=( "+set" "txAdminEnabled" "${TXADMIN_ENABLE}" )
[[ -n "${FIVEM_PORT:-}" ]] && STARTUP_CMD+=( "+set" "sv_endpoint_add_tcp" "0.0.0.0:${FIVEM_PORT}" "+set" "sv_endpoint_add_udp" "0.0.0.0:${FIVEM_PORT}" )

echo -e "${BLUE}[*] Preparing to start container with command:${RESET}"
printf "${BOLD}:/home/container$ %q ${STARTUP_CMD[@]}${RESET}\n"

# If txAdmin is enabled, show txAdmin URL
if [[ "${TXADMIN_ENABLE:-0}" == "1" ]]; then
    PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "127.0.0.1")
    PROTOCOL="http"
    echo -e "${GREEN}[+] txAdmin should be available at: ${PROTOCOL}://${PUBLIC_IP}:${TXADMIN_PORT}${RESET}"
else
    echo -e "${YELLOW}[*] txAdmin is disabled.${RESET}"
fi

# Mini runtime health check (optional but safe)
[[ ! -f "./server.cfg" ]] && echo -e "${RED}[!] server.cfg not found! Startup may fail.${RESET}"
[[ ! -d "./resources" ]] && echo -e "${YELLOW}[!] Warning: No /resources folder detected.${RESET}"

# Final Launch
exec "${STARTUP_CMD[@]}"
