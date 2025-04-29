# Use Pterodactyl's Debian yolk as the base image
FROM ghcr.io/parkervcp/yolks:debian

# Maintainer Info
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl wget unzip xz-utils file jq ca-certificates \
    libstdc++6 libgcc-s1 libc6 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /home/container

# Download and extract dms-repo
RUN echo "[*] Downloading Darkmatter repo..." && \
    curl -sSL -o master.zip https://github.com/Captainpax/dms-repo/archive/refs/heads/master.zip && \
    unzip master.zip && \
    rm master.zip && \
    echo "[*] Moving project files..." && \
    cp -a dms-repo-master/dockers/games/gtav/fivem/. /home/container/ && \
    echo "[*] Cleaning up extra files..." && \
    rm -rf dms-repo-master

# Make scripts executable
RUN chmod +x /home/container/install.sh /home/container/entrypoint.sh

# Expose default FiveM server ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Healthcheck: verify FXServer exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# Set default entrypoint
ENTRYPOINT ["/home/container/entrypoint.sh"]