# Archipelago Standalone Docker Image

This directory contains the Docker definition for running an Archipelago multiworld server on the DarkMatterServers platform. The image is based on the official Pterodactyl Python 3.10 yolk and expects the Archipelago server source to be present in the build context under `Archipelago/`. If the folder is absent the build now succeeds but emits a warning, leaving `/home/container` empty so you can populate it later via volume mounts or runtime scripts.

## Build context layout

```
Archipelago/
└── requirements.txt
```

Any additional files required by the server (configuration, data packs, etc.) should reside inside the `Archipelago/` folder so they are copied into `/home/container`.

## Build instructions

```bash
docker build -t dms/archipelago:standalone dockers/games/archipelago/standalone
```

## Runtime

The container exposes port `3333` and now starts the server through the generated `StartArchipelago` script (also symlinked to `StartAP` for backward compatibility). The wrapper automatically prefers `Archipelago.py`, falls back to legacy `ArchipelagoServer.py`, and finally tries `python3 -m Archipelago`, ensuring the launch command matches whichever entrypoint ships with the upstream tree. Provide environment variables and mounted volumes as needed when running the container.
