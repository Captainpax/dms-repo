# DMS FiveM Server Image for Pterodactyl
FROM captainpax/dms-base

LABEL maintainer="AntimatterZone LLC <support@antimatterzone.net>"
LABEL description="DMS FiveM Server Image (Ubuntu 25.04, Pterodactyl Ready)"

# Switch back to root temporarily
USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install FiveM dependencies
RUN apt update && \
    apt install -y --no-install-recommends \
        git \
        xz-utils \
        file \
        unzip \
        curl \
        libatomic1 \
        libstdc++6 \
        libcurl4 \
        libgomp1 && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Prepare folders
RUN mkdir -p /home/container/alpine/opt/cfx-server /home/container/resources /home/container/logs

# Switch back to container user
USER container
WORKDIR /home/container
