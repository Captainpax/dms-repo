# Use Ubuntu 24.04 for full glibc compatibility and modern packages
FROM ubuntu:24.04

# Maintainer Info
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# Set environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Update, install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl wget git unzip xz-utils file jq ca-certificates \
    bash libstdc++6 libgcc-s1 libc6 libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# Create container folder structure manually
RUN mkdir -p /home/container/opt/cfx-server /home/container/resources /home/container/logs /home/container/cache

# Set working directory
WORKDIR /home/container

# Download latest entrypoint.sh, install.sh, and server.cfg directly to /home/container
RUN curl -fsSL https://cloud.antimatterzone.net/s/9DzxCAFpSNMok6E/download/entrypoint.sh -o /home/container/entrypoint.sh && \
    curl -fsSL https://cloud.antimatterzone.net/s/FpWTPSHS5C2YBpM/download/install.sh -o /home/container/install.sh && \
    curl -fsSL https://cloud.antimatterzone.net/s/5ikTrqTCSdSoPjq/download/server.cfg -o /home/container/server.cfg && \
    chmod +x /home/container/entrypoint.sh /home/container/install.sh

# Set correct ownership for Pterodactyl (user 1000)
RUN chown -R 1000:1000 /home/container

# Expose default FiveM ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Healthcheck to verify FXServer exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# Run everything as Pterodactyl user 1000:1000
USER 1000:1000

# Set default entrypoint
ENTRYPOINT ["/home/container/entrypoint.sh"]
