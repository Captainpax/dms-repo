# Use Pterodactyl's Debian yolk as the base image
FROM ghcr.io/parkervcp/yolks:debian

# Maintainer Info
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# Environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies for FiveM
RUN apt update && apt install -y --no-install-recommends \
    curl wget git unzip xz-utils file jq ca-certificates \
    libstdc++6 libgcc-s1 libc6 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /home/container

# Copy scripts and configs into the image
COPY ./install.sh /install.sh
COPY ./entrypoint.sh /entrypoint.sh
COPY ./server.cfg /home/container/server.cfg

# Make scripts executable
RUN chmod +x /install.sh /entrypoint.sh

# Expose default FiveM and txAdmin ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Healthcheck: ensure FXServer binary exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD [ -f "/home/container/opt/cfx-server/FXServer" ] || exit 1

# Set default entrypoint
ENTRYPOINT ["/entrypoint.sh"]
