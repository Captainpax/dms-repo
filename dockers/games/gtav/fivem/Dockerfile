# 🧱 Use Pterodactyl's Debian yolk as base
FROM ghcr.io/pterodactyl/yolks:debian

# 👤 Become root for installation
USER root

# 🧰 Install Node.js v23, native dependencies, and Wine (with i386 support)
RUN dpkg --add-architecture i386 && \
    curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get update && \
    apt-get install -y \
        nodejs \
        curl \
        xz-utils \
        ca-certificates \
        gnupg \
        tar \
        build-essential \
        python3 \
        make \
        g++ \
        wine64 \
        wine32 \
        winbind \
        cabextract \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 🍷 Configure Wine environment and initialize prefix ahead of file copy
ENV WINEARCH=win64 \
    WINEPREFIX=/home/container/wine

RUN mkdir -p /home/container && \
    chown -R 1000:1000 /home/container && \
    runuser -u container -- wineboot --init

# 📂 Set working dir early
WORKDIR /home/container

# 📂 Copy in your initializer and manifest files
COPY home/container/ /home/container/

# 📦 Install Node dependencies (per package.json)
RUN if [ -f package.json ]; then \
      npm install --omit=dev; \
    else \
      echo "⚠️  No package.json found, skipping npm install"; \
    fi

# 🛠️ Run the FXServer build-time setup
RUN npm run setup

# 🔐 Ensure init script is executable and owned by the Pterodactyl user
RUN chmod +x initmain.mjs && \
    chown -R 1000:1000 /home/container

# 👤 Drop back to container user (UID 1000) for runtime
USER 1000

# 🚀 Runtime command: this will invoke `initmain.mjs -start`
CMD ["npm", "run", "start"]

# 📡 Expose default FiveM & txAdmin ports
EXPOSE 30120/tcp 30120/udp 40120/udp
