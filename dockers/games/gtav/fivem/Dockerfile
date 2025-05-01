# ---------------------------------------------
# 🐧 Base: Ubuntu 24.04 (glibc + security updates)
# ---------------------------------------------
FROM ubuntu:24.04

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ⚙️ Environment configuration
ENV HOME=/home/container

# ---------------------------------------------
# 📦 Install essential runtime dependencies
# ---------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash curl wget git unzip xz-utils file jq \
        libstdc++6 libgcc-s1 libc6 libcurl4 ca-certificates \
        tree gettext && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📂 Create required directory structure
# ---------------------------------------------
RUN mkdir -p ${HOME}/opt/cfx-server \
             ${HOME}/resources \
             ${HOME}/logs \
             ${HOME}/cache

# ---------------------------------------------
# 📁 Copy runtime assets (scripts, cfg, archive)
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# ✅ Set ownership and permissions
RUN chmod +x ${HOME}/entrypoint.sh ${HOME}/install.sh && \
    chown -R 1000:1000 ${HOME}

# ---------------------------------------------
# 🌐 Expose FiveM and txAdmin ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck: ensure FXServer is installed
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# 👤 Use Pterodactyl's standard UID
USER 1000:1000

# 🚀 Entrypoint script
WORKDIR /home/container
ENTRYPOINT ["/home/container/entrypoint.sh"]
