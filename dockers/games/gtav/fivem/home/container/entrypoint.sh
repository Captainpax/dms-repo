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

# ----------------------------------
# Prompt for missing environment variables
# ----------------------------------

prompt_if_missing() {
  local var_name="$1"
  local prompt_msg="$2"
  local default_value="${3:-}"

  if [[ -z "${!var_name:-}" ]]; then
    if [[ -n "$default_value" ]]; then
      read -rp "$prompt_msg [$default_value]: " input
      export "$var_name"="${input:-$default_value}"
    else
      read -rp "$prompt_msg: " input
      export "$var_name"="$input"
    fi
  fi
}

prompt_if_missing "FIVEM_LICENSE" "Enter your FiveM License Key"
prompt_if_missing "STEAM_WEBAPIKEY" "Enter your Steam Web API Key" "changeme"
prompt_if_missing "ONESYNC_STATE" "Enable OneSync? (on/off)" "on"
prompt_if_missing "PROJECT_NAME" "Enter Project Name" "Darkmatter Server"
prompt_if_missing "PROJECT_DESCRIPTION" "Enter Project Description" "Welcome to Darkmatter!"
prompt_if_missing "TXADMIN_PORT" "Enter txAdmin Port" "40120"
prompt_if_missing "TXADMIN_ENABLE" "Enable txAdmin? (1 = yes, 0 = no)" "1"
prompt_if_missing "FIVEM_PORT" "Enter base FiveM port" "30120"
prompt_if_missing "FIVEM_VERSION" "Enter FiveM Build Version (recommended/latest/custom)" "recommended"
[[ -z "${GAME_BUILD:-}" ]] && read -rp "Enter Game Build Number (or leave blank): " GAME_BUILD

# ----------------------------------
# Ensure FXServer is installed
# ----------------------------------

if [[ ! -f "./opt/cfx-server/FXServer" ]]; then
  echo -e "${YELLOW}[!] FXServer binary not found. Running installer...${RESET}"

  FIVEM_VERSION="${FIVEM_VERSION}" \
  GAME_BUILD="${GAME_BUILD:-}" \
  bash "./install.sh" || {
    echo -e "${RED}[!] Install failed. Retrying in 3 seconds...${RESET}"
    sleep 3
    FIVEM_VERSION="${FIVEM_VERSION}" \
    GAME_BUILD="${GAME_BUILD:-}" \
    bash "./install.sh" || {
      echo -e "${RED}[-] Install failed again. Aborting.${RESET}"
      exit 1
    }
  }
  sleep 1
else
  echo -e "${GREEN}[+] FXServer binary found. Skipping install.${RESET}"
fi

# ----------------------------------
# Display build info
# ----------------------------------

if [[ -f "./.fivem_build" ]]; then
  BUILD_VERSION=$(< ./.fivem_build)
  echo -e "${CYAN}[*] Installed FiveM Build: ${BOLD}${BUILD_VERSION}${RESET}"
fi

# ----------------------------------
# Build startup command
# ----------------------------------

STARTUP_CMD="./opt/cfx-server/FXServer +exec server.cfg"
STARTUP_CMD+=" +set sv_licenseKey \"${FIVEM_LICENSE}\""
STARTUP_CMD+=" +set steam_webApiKey \"${STEAM_WEBAPIKEY}\""
STARTUP_CMD+=" +set onesync \"${ONESYNC_STATE}\""

[[ -n "${GAME_BUILD}" ]] && STARTUP_CMD+=" +set sv_enforceGameBuild ${GAME_BUILD}"

STARTUP_CMD+=" +sets sv_projectName \"${PROJECT_NAME}\""
STARTUP_CMD+=" +sets sv_projectDesc \"${PROJECT_DESCRIPTION}\""
STARTUP_CMD+=" +set txAdminPort ${TXADMIN_PORT}"
STARTUP_CMD+=" +set txAdminEnabled ${TXADMIN_ENABLE}"
STARTUP_CMD+=" +set sv_endpoint_add_tcp \"0.0.0.0:${FIVEM_PORT}\""
STARTUP_CMD+=" +set sv_endpoint_add_udp \"0.0.0.0:${FIVEM_PORT}\""

# ----------------------------------
# Launch Summary
# ----------------------------------

echo -e "${BLUE}[*] Launching with command:${RESET}"
echo -e "${BOLD}:/home/container$ ${STARTUP_CMD}${RESET}"

if [[ "${TXADMIN_ENABLE}" == "1" ]]; then
  PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "127.0.0.1")
  echo -e "${GREEN}[+] txAdmin available at: http://${PUBLIC_IP}:${TXADMIN_PORT}${RESET}"
else
  echo -e "${YELLOW}[*] txAdmin is disabled.${RESET}"
fi

[[ ! -f "./opt/cfx-server/server.cfg" ]] && echo -e "${RED}[!] Warning: opt/cfx-server/server.cfg missing! Startup may fail.${RESET}"
[[ ! -d "./resources" ]] && echo -e "${YELLOW}[!] No /resources/ folder detected.${RESET}"

# ----------------------------------
# Run Server
# ----------------------------------

exec /bin/bash -c "${STARTUP_CMD}"