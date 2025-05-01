# ---------------------------------------------
# 🐧 Base: Ubuntu 24.04 (glibc + security updates)
# ---------------------------------------------
FROM ubuntu:24.04

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# 📦 Environment and non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------
# 📦 Install required system dependencies
# ---------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget git unzip xz-utils file jq ca-certificates \
        bash libstdc++6 libgcc-s1 libc6 libcurl4 tree && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 🗂️ Create container home and data structure
# ---------------------------------------------
RUN mkdir -p /home/container/opt/cfx-server \
             /home/container/resources \
             /home/container/logs \
             /home/container/cache

# ---------------------------------------------
# 📁 Copy all runtime scripts, cfg, and fx.tar.xz
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ /home/container/

# ✅ Set permissions
RUN chmod +x /home/container/entrypoint.sh /home/container/install.sh && \
    chown -R 1000:1000 /home/container

# ---------------------------------------------
# 🌐 Expose ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck: ensure FXServer exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# 👤 Pterodactyl user
USER 1000:1000

# 🚀 Boot entrypoint
ENTRYPOINT ["/home/container/entrypoint.sh"]
