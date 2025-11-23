# Rust Dedicated Server Egg

This directory contains the DarkMatterServers Pterodactyl egg for running the Rust Dedicated Server with optional Oxide/uMod support. The egg installs Rust via SteamCMD, exposes the common gameplay/query ports, and lets you toggle plugin support with a single variable.

## Components

- `dms-rust.json` — Pterodactyl egg that installs/upgrades Rust (optionally on a non-public branch) and boots `RustDedicated` with the configured network and world settings.
- Docker image: `captainpax/dms-rust` — Base image referenced by the egg for both installation and runtime.

## Port requirements

The Rust server uses multiple ports for gameplay, queries, Rust+ websocket, and RCON. Ensure your node and panel allocations cover all of them:

| Purpose | Variable | Default |
| --- | --- | --- |
| Game traffic | `GAME_PORT` | `28015` |
| Server query | `QUERY_PORT` | `28016` |
| Rust+ app websocket | `RUSTPLUS_PORT` | `28082` |
| RCON | `RCON_PORT` | `28017` |

The startup command binds `RustDedicated` to `0.0.0.0` for game, query, Rust+, and RCON endpoints so the panel allocation determines exposure.

## Required environment variables

Import the egg and configure these variables (defaults shown below are baked into the egg):

| Variable | Purpose | Default |
| --- | --- | --- |
| `GAME_PORT` | Base port for gameplay traffic. | `28015` |
| `QUERY_PORT` | Query/listing port. | `28016` |
| `RUSTPLUS_PORT` | Port for the Rust+ websocket service. | `28082` |
| `RCON_PORT` | Port used for RCON connections. | `28017` |
| `RCON_PASSWORD` | Password required for RCON access. | `changeme123` |
| `SERVER_NAME` | Public server name. | `Darkmatter Rust Server` |
| `SERVER_DESCRIPTION` | Description shown in the server list. | `Welcome to Darkmatter Rust!` |
| `WORLD_SEED` | Numeric world seed. | `12345` |
| `WORLD_SIZE` | Map size in meters. | `3500` |
| `MAX_PLAYERS` | Player slot count. | `50` |
| `RUST_BRANCH` | Steam branch to install (e.g., `public`, `staging`). | `public` |
| `OXIDE_ENABLED` | Enable Oxide/uMod install after updates (`1` = yes, `0` = no). | `0` |

### Example configuration

- Keep the default `public` branch unless you need a staging build for testing.
- Use matching allocations, e.g., `GAME_PORT=28015`, `QUERY_PORT=28016`, `RUSTPLUS_PORT=28082`, `RCON_PORT=28017` so the panel and startup command align.
- Set a strong `RCON_PASSWORD` (6–64 characters) before bringing the server online.

## Importing into Pterodactyl

1. In the Pterodactyl admin panel, navigate to **Nests → Import Egg** and upload `dms-rust.json`.
2. Assign the server the `captainpax/dms-rust` image and confirm the default startup command if prompted.
3. Create port allocations for the game, query, Rust+, and RCON ports listed above, then map them to the corresponding variables when deploying a server.
4. Adjust world settings (`WORLD_SEED`, `WORLD_SIZE`, `MAX_PLAYERS`) and branding (`SERVER_NAME`, `SERVER_DESCRIPTION`) as desired.

## Enabling Oxide/uMod

Set `OXIDE_ENABLED` to `1` to have the installer download and unpack Oxide/uMod after each SteamCMD update. The script pulls the latest build from `https://umod.org/games/rust/download` and overlays it onto the Rust installation. Leave `OXIDE_ENABLED` at `0` to run the vanilla server.

## Startup behavior

The egg runs `RustDedicated` with `-batchmode` and wires in the configured ports, identity (`dms_rust`), hostname, seed, world size, description, and player cap. RCON is enabled with web RCON (`+rcon.web 1`) bound to all interfaces using your configured port and password.
