# Archipelago Standalone Docker Image

This directory contains the Docker definition for running an Archipelago multiworld server on the DarkMatterServers platform. The image is based on the official Pterodactyl Python 3.10 yolk and now retrieves the Archipelago sources automatically during build.

## Automated source retrieval

By default the Dockerfile downloads the latest vetted upstream archive from the DarkMatterServers mirror:

- **URL:** `https://cloud.antimatterzone.net/s/bNZ57tEMd5downP/download`
- **Authentication:** The share link is public and does not require credentials.

The archive is unpacked into `/home/container/Archipelago`, aligning with the generated start script that runs within that directory. If the upstream packaging ever changes, adjust the Dockerfile logic so that `Archipelago.py` (or another valid entrypoint) continues to reside directly inside `/home/container/Archipelago`.

### Overriding the download

Self-hosted mirrors or development builds can replace the automatic download by dropping an `Archipelago/` directory next to the Dockerfile before running `docker build`. The build detects any contents placed inside that folder and copies them into the image instead of fetching the hosted archive. You can also override the download URL via the `ARCHIPELAGO_SOURCE_URL` build argument:

```bash
docker build \
  --build-arg ARCHIPELAGO_SOURCE_URL="https://example.com/custom-archive.zip" \
  -t dms/archipelago:standalone \
  dockers/games/archipelago/standalone
```

When overriding with a local tree the layout inside `Archipelago/` should match the upstream structure (i.e., contain `Archipelago.py`, `requirements.txt`, etc.) so the bootstrap script and dependency installation continue to work.

## Build instructions

```bash
docker build -t dms/archipelago:standalone dockers/games/archipelago/standalone
```

## Runtime

The container exposes port `3333` and starts the server through the generated `StartArchipelago` script (also symlinked to `StartAP` for backward compatibility). The wrapper automatically prefers `Archipelago.py`, falls back to legacy `ArchipelagoServer.py`, and finally tries `python3 -m Archipelago`, ensuring the launch command matches whichever entrypoint ships with the upstream tree. Provide environment variables and mounted volumes as needed when running the container.
