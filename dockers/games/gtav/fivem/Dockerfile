# 🧼 Base FXServer image
FROM routmoute/fxserver:recommended

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ⚙️ Environment
ENV HOME=/home/container
WORKDIR ${HOME}

# 👑 Become root to install deps and copy files
USER root

# 📦 Install Alpine-compatible Node.js + npm
RUN apk add --no-cache nodejs npm

# 📂 Copy server files
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# 📦 Install Node dependencies if package.json exists
RUN if [ -f "${HOME}/package.json" ]; then npm install --omit=dev; fi

# ✅ Set correct permissions for Pterodactyl (uses UID/GID 1000 = cfx)
RUN chmod +x ${HOME}/initmain.mjs && \
    chown -R cfx:cfx ${HOME}

# 🌐 Expose FXServer and txAdmin ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Optional healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD test -x ${HOME}/initmain.mjs

# 👤 Switch to correct user
USER cfx

# 🚀 Entrypoint
ENTRYPOINT ["node", "--no-warnings", "--enable-source-maps", "/home/container/initmain.mjs"]