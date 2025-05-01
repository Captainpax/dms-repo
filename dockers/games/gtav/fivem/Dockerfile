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
        bash libstdc++6 libgcc-s1 libc6 libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 🗂️ Create container home and data structure
# ---------------------------------------------
RUN mkdir -p /home/container/opt/cfx-server \
             /home/container/resources \
             /home/container/logs \
             /home/container/cache

# ---------------------------------------------
# 📁 Copy runtime scripts and static FXServer build
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ /home/container/

# ✅ Set permissions
RUN chmod +x /home/container/entrypoint.sh /home/container/install.sh && \
    chown -R 1000:1000 /home/container

# ---------------------------------------------
# 🌐 Expose default FiveM and txAdmin ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck: validate FXServer exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# 👤 Run as Pterodactyl container user (UID 1000)
USER 1000:1000

# 🚀 Entrypoint script
ENTRYPOINT ["/home/container/entrypoint.sh"]
