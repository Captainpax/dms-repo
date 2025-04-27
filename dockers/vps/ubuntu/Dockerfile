# DMS VPS Image for Pterodactyl
FROM captainpax/dms-base

LABEL maintainer="AntimatterZone LLC <support@antimatterzone.net>"
LABEL description="DMS VPS Image with SSH, Firewall, and Admin User Setup (Pterodactyl Ready)"

# Switch back to root temporarily
USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install necessary server packages
RUN apt update && \
    apt install -y --no-install-recommends \
        openssh-server \
        sudo \
        nano \
        ufw \
        tzdata \
        curl \
        bash && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Setup SSH directory
RUN mkdir -p /var/run/sshd

# Switch back to container user for normal Pterodactyl startup
USER container
WORKDIR /home/container
