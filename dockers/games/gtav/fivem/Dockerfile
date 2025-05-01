# Use Ubuntu 24.04 for full glibc compatibility and modern packages
FROM ubuntu:24.04

# Maintainer Info
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# Set environment settings
ENV DEBIAN_FRONTEND=noninteractive

# Install required runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl wget git unzip xz-utils file jq ca-certificates \
        bash libstdc++6 libgcc-s1 libc6 libcurl4 && \
    rm -rf /var/lib/apt/lists/*

# Create container folder structure
RUN mkdir -p /home/container/opt/cfx-server \
             /home/container/resources \
             /home/container/logs \
             /home/container/cache

# Set working directory
WORKDIR /home/container

# Copy local scripts and server.cfg into the container
COPY home/container/entrypoint.sh /home/container/entrypoint.sh
COPY home/container/install.sh    /home/container/install.sh
COPY home/container/server.cfg    /home/container/server.cfg

# Make scripts executable
RUN chmod +x /home/container/entrypoint.sh /home/container/install.sh

# Set correct ownership for Pterodactyl's container user (1000)
RUN chown -R 1000:1000 /home/container

# Expose default FiveM and txAdmin ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Healthcheck to verify FXServer exists
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# Switch to container user (Pterodactyl uses uid 1000)
USER 1000:1000

# Entrypoint
ENTRYPOINT ["/home/container/entrypoint.sh"]