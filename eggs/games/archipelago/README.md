# Archipelago Multiworld Server Deployment

This directory contains the DarkMatterServers egg and related documentation for running the [Archipelago multiworld server](https://archipelago.gg/). Use it together with the Docker image defined in `dockers/games/archipelago/` to provide a reproducible build of the upstream project on Pterodactyl.

## Components

- `dms-archipelago.json` — Pterodactyl egg that bootstraps Archipelago inside a Python virtual environment and wires the launch script used by DarkMatterServers.
- `dockers/games/archipelago/standalone/Dockerfile` — Builds the runtime image and generates the `StartArchipelago` script (symlinked to `StartAP`) that automatically launches the correct upstream entrypoint.

## Prerequisites

The Docker build expects the Archipelago source tree to be present in the build context under `Archipelago/` with an optional `requirements.txt`. The build stage copies those files into `/home/container/`, installs dependencies when `requirements.txt` exists, and writes the executable `StartArchipelago` wrapper (also exposed as `StartAP`). The wrapper searches for `Archipelago.py`, then `ArchipelagoServer.py`, and finally attempts `python3 -m Archipelago` so new and legacy upstream trees boot without manual edits.

Because `StartAP` is baked at build time, rebuild the image whenever you update the upstream Archipelago files. The container exposes TCP port **3333** by default, mirroring the stock Archipelago configuration.

## Required environment variables

Import the egg into Pterodactyl and configure the following variables so the generated `start.sh` script knows how to launch the server:

| Variable | Purpose | Default |
| --- | --- | --- |
| `ARCHIPELAGO_REPOSITORY` | Git repository containing Archipelago. | `https://github.com/ArchipelagoMW/Archipelago.git` |
| `ARCHIPELAGO_BRANCH` | Branch or tag checked out during install/update. | `main` |
| `SERVER_HOST` | Network interface Archipelago should bind to. | `0.0.0.0` |
| `SERVER_PORT` | Runtime port forwarded to the Archipelago server process. Set to `3333` to match the Dockerfile exposure. | `38281` |
| `SERVER_PASSWORD` | Optional connection password for players. | (empty) |

The installation script also provisions a `.venv` virtual environment and writes `/home/container/start.sh`, which activates the environment and forwards the host, port, and optional password to the container's `StartArchipelago` wrapper.

## Using the egg with the Docker image

1. **Build the image**
   ```bash
   docker build -t dms/archipelago:standalone dockers/games/archipelago/standalone
   ```
   Ensure the build context contains an `Archipelago/` directory as described above.
2. **Import the egg** into your Pterodactyl panel and assign the `dms/archipelago:standalone` image to the server.
3. **Configure variables** using the table above. Override `SERVER_PORT` to `3333` (or adjust container port mappings) so the panel and container agree on the listening port used by the baked-in `StartAP` script.
4. **Start the server.** The panel runs `bash /home/container/start.sh`, which in turn activates the virtual environment and execs the container's `StartArchipelago` bootstrap (also reachable as `./StartAP`). The script hands control to whichever upstream entrypoint is available, ensuring the server binds to the configured host/port without extra maintenance.

This pairing keeps the build-time logic (dependency installation and script generation) in the Docker layer while the egg handles runtime updates and configuration, producing consistent Archipelago deployments across DarkMatterServers infrastructure.
