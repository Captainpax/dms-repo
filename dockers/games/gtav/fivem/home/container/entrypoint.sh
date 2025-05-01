#!/bin/bash
# DMS FiveM Entrypoint Script - by Darkmatter Servers (Antimatter Zone LLC)

set -euo pipefail

# Colors
BOLD="\033[1m"; RESET="\033[0m"
GREEN="\033[1;32m"; YELLOW="\033[1;33m"; RED="\033[1;31m"; BLUE="\033[1;34m";

cd /home/container || {
  echo -e "${RED}[-] Failed to cd to /home/container${RESET}"
  exit 1
}

# Prompt helper
prompt_if_missing() {
  local var="$1" msg="$2" default="${3:-}"
  if [[ -z "${!var:-}" ]]; then
    if [[ -n "$default" ]]; then
      read -rp "$msg [$default]: " val
      export "$var"="${val:-$default}"
    else
      read -rp "$msg: " val
      export "$var"="$val"
    fi
  fi
}

# Prompt for required variables
prompt_if_missing "FIVEM_LICENSE"       "Enter your FiveM License Key"
prompt_if_missing "STEAM_WEBAPIKEY"     "Enter your Steam Web API Key" "changeme"
prompt_if_missing "ONESYNC_STATE"       "Enable OneSync? (on/off)" "on"
prompt_if_missing "PROJECT_NAME"        "Enter Project Name" "Darkmatter Server"
prompt_if_missing "PROJECT_DESCRIPTION" "Enter Project Description" "Welcome to Darkmatter!"
prompt_if_missing "TXADMIN_PORT"        "Enter txAdmin Port" "40120"
prompt_if_missing "TXADMIN_ENABLE"      "Enable txAdmin? (1 = yes, 0 = no)" "1"
prompt_if_missing "FIVEM_PORT"          "Enter base FiveM port" "30120"
prompt_if_missing "SERVER_HOSTNAME"     "Enter server hostname" "DMS 5M Server"
prompt_if_missing "MAX_PLAYERS"         "Max player slots" "32"
prompt_if_missing "RCON_PASSWORD"       "Enter RCON password" "changeme"
[[ -z "${GAME_BUILD:-}" ]] && read -rp "Enter Game Build Number (or leave blank): " GAME_BUILD

FXSERVER_BIN="./opt/cfx-server/FXServer"
SERVER_CFG="./opt/cfx-server/server.cfg"
RESOURCES_DIR="./resources"

# Check FXServer binary
if [[ ! -x "$FXSERVER_BIN" ]]; then
  echo -e "${RED}[-] FXServer binary missing or not executable at $FXSERVER_BIN${RESET}"
  exit 1
fi

# Startup line
STARTUP_CMD=("$FXSERVER_BIN" "+exec" "server.cfg")
STARTUP_CMD+=("+set" "sv_licenseKey" "$FIVEM_LICENSE")
STARTUP_CMD+=("+set" "steam_webApiKey" "$STEAM_WEBAPIKEY")
STARTUP_CMD+=("+set" "onesync" "$ONESYNC_STATE")
[[ -n "${GAME_BUILD:-}" ]] && STARTUP_CMD+=("+set" "sv_enforceGameBuild" "$GAME_BUILD")
STARTUP_CMD+=("+sets" "sv_projectName" "$PROJECT_NAME")
STARTUP_CMD+=("+sets" "sv_projectDesc" "$PROJECT_DESCRIPTION")
STARTUP_CMD+=("+set" "txAdminPort" "$TXADMIN_PORT")
STARTUP_CMD+=("+set" "txAdminEnabled" "$TXADMIN_ENABLE")
STARTUP_CMD+=("+set" "sv_endpoint_add_tcp" "0.0.0.0:${FIVEM_PORT}")
STARTUP_CMD+=("+set" "sv_endpoint_add_udp" "0.0.0.0:${FIVEM_PORT}")

# Summary
echo -e "${BLUE}[*] Final startup command:${RESET}"
echo -e "${BOLD}:/home/container$ ${STARTUP_CMD[*]}${RESET}"

if [[ "$TXADMIN_ENABLE" == "1" ]]; then
  PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org || echo "127.0.0.1")
  echo -e "${GREEN}[+] txAdmin available at: http://${PUBLIC_IP}:${TXADMIN_PORT}${RESET}"
fi

[[ ! -f "$SERVER_CFG" ]] && echo -e "${RED}[!] Warning: server.cfg missing at ${SERVER_CFG}${RESET}"
[[ ! -d "$RESOURCES_DIR" ]] && echo -e "${YELLOW}[!] Warning: No resources/ directory found!${RESET}"

# Launch
exec "${STARTUP_CMD[@]}"