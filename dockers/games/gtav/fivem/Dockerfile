# Use Pterodactyl's Debian yolk as the base image
FROM ghcr.io/parkervcp/yolks:debian

# Maintainer (optional)
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# Environment
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies for FiveM
RUN apt update && apt install -y --no-install-recommends \
    curl \
    wget \
    git \
    unzip \
    xz-utils \
    ca-certificates \
    libstdc++6 \
    libgcc-s1 \
    libc6 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /home/container

# Copy scripts into the image
COPY ./install.sh /install.sh
COPY ./entrypoint.sh /entrypoint.sh

# Make scripts executable
RUN chmod +x /install.sh /entrypoint.sh

# RUN install.sh during the build!
RUN /install.sh

# Expose FiveM server ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# Default entrypoint
ENTRYPOINT ["/entrypoint.sh"]
