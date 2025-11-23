# Rust Dedicated Server Docker Image

This image installs SteamCMD, downloads the latest Rust Dedicated Server build, and can optionally layer in Oxide/uMod plugins. It exposes the default Rust ports and ships with a small start script that respects common server environment variables. The image now builds from the standard `debian:bookworm-slim` base to avoid pulling unavailable GHCR yolks while keeping parity with Pterodactyl expectations (including a `container` user with UID/GID 1000). Additional 32-bit runtime libraries (e.g., `libc6-i386`, `lib32z1`, `libcurl4-gnutls-dev:i386`) are installed so SteamCMD can bootstrap without the `steamconsole.so` missing-library error and to satisfy Rust's bundled 32-bit dependencies.

## Building

```bash
docker build \
  -t dms/rust:latest \
  --build-arg INCLUDE_OXIDE=true \
  --build-arg OXIDE_DOWNLOAD_URL=https://umod.org/games/rust/download \
  dockers/games/rust
```

### Build arguments
- `INCLUDE_OXIDE` (default: `true`): Set to `false` to skip downloading and extracting Oxide/uMod during build.
- `OXIDE_DOWNLOAD_URL` (default: `https://umod.org/games/rust/download`): Override to point at a specific Oxide/uMod package.
- `RUST_APP_ID` (default: `258550`): Steam app ID for the Rust Dedicated Server. Override only if you know what you are doing.

## Runtime

The start script runs `RustDedicated` with sane defaults and picks up the following environment variables:

- `RUST_SERVER_IP` (default: `0.0.0.0`): Bind address for game and query traffic.
- `RUST_SERVER_PORT` (default: `28015`): Game port (TCP/UDP).
- `RUST_SERVER_QUERY_PORT` (default: `28015`): Query port for server listings.
- `RUST_RCON_IP` (default: `0.0.0.0`): Bind address for RCON.
- `RUST_RCON_PORT` (default: `28016`): RCON port (TCP).
- `RUST_RCON_PASSWORD` (default: `changeme`): RCON password; **change this in production**.
- `RUST_RCON_WEB` (default: `1`): Enable the web RCON interface (`0` disables).
- `RUST_SERVER_IDENTITY` (default: `dms-rust`): Server identity folder under `server/`.
- `RUST_SERVER_SEED` (default: `1337`): Map seed for procedural generation.
- `RUST_SERVER_WORLDSIZE` (default: `3500`): Map size in meters.
- `RUST_SERVER_MAXPLAYERS` (default: `50`): Player cap.
- `RUST_SERVER_NAME` (default: `DarkMatter Rust`): Server hostname.
- `RUST_SERVER_DESCRIPTION` (default: `Rust dedicated server`): Description shown in the browser.
- `RUST_SERVER_SAVE_INTERVAL` (default: `300`): Save interval in seconds.
- `RUST_ADDITIONAL_ARGS` (default: empty): Extra arguments appended to the launch command.

### Volumes

Mount these paths to persist game files, save data, and logs:
- `/home/container/server`: Core installation and binaries.
- `/home/container/server/server`: Identity data (maps, storage, Oxide data, etc.).
- `/home/container/server/logs`: Server logs.

### Ports

The container exposes:
- `28015/tcp` and `28015/udp` (game + query)
- `28016/tcp` and `28016/udp` (RCON; UDP included for completeness)

### Example run

```bash
docker run -d \
  --name rust-server \
  -p 28015:28015/tcp -p 28015:28015/udp \
  -p 28016:28016/tcp -p 28016:28016/udp \
  -v rust-data:/home/container/server \
  -v rust-identities:/home/container/server/server \
  -v rust-logs:/home/container/server/logs \
  -e RUST_SERVER_NAME="My Rust Server" \
  -e RUST_RCON_PASSWORD="supersecret" \
  dms/rust:latest
```
