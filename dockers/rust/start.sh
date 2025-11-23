#!/bin/bash
set -euo pipefail

cd /home/container/server

# Ensure RustDedicated is present
if [ ! -x ./RustDedicated ]; then
  echo "RustDedicated binary not found. Did the install succeed?" >&2
  exit 1
fi

exec ./RustDedicated \
  -batchmode \
  +server.ip "${RUST_SERVER_IP:-0.0.0.0}" \
  +server.port "${RUST_SERVER_PORT:-28015}" \
  +server.queryport "${RUST_SERVER_QUERY_PORT:-28015}" \
  +rcon.ip "${RUST_RCON_IP:-0.0.0.0}" \
  +rcon.port "${RUST_RCON_PORT:-28016}" \
  +rcon.password "${RUST_RCON_PASSWORD:-changeme}" \
  +rcon.web "${RUST_RCON_WEB:-1}" \
  +server.identity "${RUST_SERVER_IDENTITY:-dms-rust}" \
  +server.seed "${RUST_SERVER_SEED:-1337}" \
  +server.worldsize "${RUST_SERVER_WORLDSIZE:-3500}" \
  +server.maxplayers "${RUST_SERVER_MAXPLAYERS:-50}" \
  +server.hostname "${RUST_SERVER_NAME:-DarkMatter Rust}" \
  +server.description "${RUST_SERVER_DESCRIPTION:-Rust dedicated server}" \
  +server.saveinterval "${RUST_SERVER_SAVE_INTERVAL:-300}" \
  ${RUST_ADDITIONAL_ARGS:-}
