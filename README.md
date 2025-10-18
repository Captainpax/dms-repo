# DarkMatterServers Custom Docker Repository

This repository hosts the custom Docker configurations and related deployment assets for DarkMatterServers.com. Use it to manage,
configure, and document the Docker images and runtime environments that power the platform.

## Repository Layout

- `dockers/` — Service-specific Docker definitions, scripts, and resources.
- `eggs/` — Supplemental assets such as templates or shared build components.
  - [`eggs/games/archipelago/`](eggs/games/archipelago/README.md) — Guide for pairing the Archipelago egg with its Docker image.
- `deploy.sh` — Entry point for deployment orchestration.

## Contributing

1. Create or update Docker resources inside the relevant directory.
2. Document every change you make in either a dedicated README within the service directory or the main README when appropriate.
3. Explain deployment considerations, environment variables, and runtime expectations so others can operate the service confidently.
4. Follow the guidelines in `AGENTS.md` and provide clear commit messages referencing the work performed.

## Support

For questions or operational support, reach out to the DarkMatterServers infrastructure team.
