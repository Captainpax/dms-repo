# ---------------------------------------------
# 🐧 Base Image: Ubuntu 24.04 (glibc + security updates)
# ---------------------------------------------
FROM ubuntu:24.04

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ---------------------------------------------
# ⚙️ Environment
# ---------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/container

# ---------------------------------------------
# 📦 Install runtime dependencies
# ---------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash curl wget git unzip xz-utils file jq \
        libstdc++6 libgcc-s1 libc6 libcurl4 \
        ca-certificates tree gettext && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📁 Prepare container directory structure
# ---------------------------------------------
RUN mkdir -p "$HOME"/{opt/cfx-server,resources,logs,cache}

# ---------------------------------------------
# 📁 Copy static server payload (scripts + cfg + fx.tar.xz)
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ "$HOME"/

# ---------------------------------------------
# 📦 Extract FiveM binary
# (done at build time to avoid runtime install)
# ---------------------------------------------
RUN tar -xf "$HOME/fx.tar.xz" -C "$HOME/opt/cfx-server" && \
    if [ -d "$HOME/opt/cfx-server/alpine/opt/cfx-server" ]; then \
      echo "[!] Flattening nested alpine structure..."; \
      cp -a "$HOME/opt/cfx-server/alpine/opt/cfx-server/." "$HOME/opt/cfx-server/" && \
      rm -rf "$HOME/opt/cfx-server/alpine"; \
    fi && \
    rm -f "$HOME/fx.tar.xz"

# ---------------------------------------------
# ✅ Set permissions for scripts and container ownership
# ---------------------------------------------
RUN chmod +x "$HOME"/entrypoint.sh "$HOME"/install.sh && \
    chown -R 1000:1000 "$HOME"

# ---------------------------------------------
# 🌐 Expose FiveM and txAdmin ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck for FXServer binary
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD [ "bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]" ]

# 👤 Required by Pterodactyl (must run as UID 1000)
USER 1000:1000

# 🏠 Required working directory (matches Pterodactyl)
WORKDIR /home/container

# 🚀 Launch script
ENTRYPOINT ["/home/container/entrypoint.sh"]