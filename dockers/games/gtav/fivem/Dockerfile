# --------------------------------------------
# Darkmatter Servers - DMS FiveM Docker Image
# Maintainer: Antimatter Zone LLC
# https://antimatterzone.net
# --------------------------------------------

# Use Pterodactyl's Debian yolk as the base image
FROM ghcr.io/parkervcp/yolks:debian

# Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"
LABEL description="Darkmatter FiveM Standalone Container for Pterodactyl"

# Environment Settings
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl wget git unzip xz-utils file jq ca-certificates \
    libstdc++6 libgcc-s1 libc6 && \
    rm -rf /var/lib/apt/lists/*

# Create folder structure manually
RUN mkdir -p \
    /home/container \
    /home/container/opt \
    /home/container/resources \
    /home/container/logs \
    /home/container/cache

# Set working directory
WORKDIR /home/container

# Download required server files
RUN curl -fsSL https://cloud.antimatterzone.net/s/9DzxCAFpSNMok6E/download/entrypoint.sh -o entrypoint.sh && \
    curl -fsSL https://cloud.antimatterzone.net/s/FpWTPSHS5C2YBpM/download/install.sh -o install.sh && \
    curl -fsSL https://cloud.antimatterzone.net/s/5ikTrqTCSdSoPjq/download/server.cfg -o server.cfg && \
    chmod +x entrypoint.sh install.sh

# Expose default FiveM ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Healthcheck to validate FXServer is installed
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# Set default container entrypoint
ENTRYPOINT ["/home/container/entrypoint.sh"]
