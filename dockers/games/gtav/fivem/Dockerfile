# ---------------------------------------------
# 🐧 Base Image: Ubuntu 24.04 (glibc + security updates)
# ---------------------------------------------
FROM ubuntu:24.04

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ---------------------------------------------
# ⚙️ Environment
# ---------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/container
WORKDIR ${HOME}

# ---------------------------------------------
# 📦 System Dependencies
# ---------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget git bash xz-utils unzip file jq ca-certificates \
    libstdc++6 libgcc-s1 libc6 libcurl4 tree gettext tar gnupg && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📥 Node.js 23.x (from Nodesource)
# ---------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# ---------------------------------------------
# 📁 Prepare layout
# ---------------------------------------------
RUN mkdir -p ${HOME}/opt/cfx-server \
             ${HOME}/resources \
             ${HOME}/logs \
             ${HOME}/cache

# ---------------------------------------------
# 📂 Copy all project files
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# ---------------------------------------------
# 📦 Install Node dependencies (for tar module)
# ---------------------------------------------
RUN npm install

# ---------------------------------------------
# ✅ Set final permissions
# ---------------------------------------------
RUN chmod +x ${HOME}/initmain.mjs && \
    chown -R 1000:1000 ${HOME}

# ---------------------------------------------
# 🌐 Expose game & txAdmin ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck for Pterodactyl binary validation
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD [ "bash", "-c", "[ -x /home/container/opt/cfx-server/FXServer ]" ]

# 👤 Pterodactyl-standard UID:GID
USER 1000:1000

# 🚀 Run initmain directly (handles setup + startup)
ENTRYPOINT ["node", "--no-warnings", "--enable-source-maps", "/home/container/initmain.mjs"]