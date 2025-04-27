#!/bin/bash
# FiveM install script for Pterodactyl

set -e

echo "[*] Starting FiveM installation..."

# Required environment variables
FIVEM_VERSION=${FIVEM_VERSION:-recommended}
FIVEM_DL_URL=${DOWNLOAD_URL:-""}

# Create directories
mkdir -p /home/container/alpine/opt/cfx-server
mkdir -p /home/container/resources
mkdir -p /home/container/logs

# Install basic dependencies
apt update && apt install -y curl git unzip xz-utils file

# Download artifacts
echo "[*] Fetching FiveM artifact info..."
RELEASE_PAGE=$(curl -sSL https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/)
CHANGELOGS_PAGE=$(curl -sSL https://changelogs-live.fivem.net/api/changelog/versions/linux/server)

if [[ "$FIVEM_VERSION" == "recommended" ]] || [[ -z "$FIVEM_VERSION" ]]; then
  DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
elif [[ "$FIVEM_VERSION" == "latest" ]]; then
  DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.latest_download')
else
  VERSION_LINK=$(echo -e "${RELEASE_PAGE}" | grep -Eo '"[^"]*\.tar\.xz"' | grep -o '[^"]*' | grep "$FIVEM_VERSION")
  if [[ -z "$VERSION_LINK" ]]; then
    echo "[!] Invalid version. Defaulting to recommended."
    DOWNLOAD_LINK=$(echo $CHANGELOGS_PAGE | jq -r '.recommended_download')
  else
    DOWNLOAD_LINK="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/${VERSION_LINK}"
  fi
fi

if [[ -n "$FIVEM_DL_URL" ]]; then
  DOWNLOAD_LINK="$FIVEM_DL_URL"
fi

echo "[*] Downloading FiveM server files..."
cd /home/container/alpine/opt/cfx-server
curl -sSL "$DOWNLOAD_LINK" -o "fivem.tar.xz"
tar -xvf fivem.tar.xz
rm fivem.tar.xz

# Download default server.cfg if not present
cd /home/container
if [[ ! -f server.cfg ]]; then
  echo "[*] Downloading default server.cfg..."
  curl -sSL https://raw.githubusercontent.com/citizenfx/cfx-server-data/master/server.cfg -o server.cfg
fi

echo "[*] FiveM installation complete!"
