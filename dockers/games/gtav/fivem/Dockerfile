# 🧼 Base FXServer image
FROM routmoute/fxserver:recommended

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ⚙️ Environment
ENV HOME=/home/container
WORKDIR ${HOME}

# 👑 Become root to modify image
USER root

# 📦 Download working Node.js binary from official Alpine Node image
RUN mkdir -p /tmp/node && \
    wget -qO- https://unofficial-builds.nodejs.org/download/release/v20.11.1/node-v20.11.1-linux-x64-musl.tar.gz \
    | tar -xz -C /tmp/node --strip-components=1 && \
    cp /tmp/node/bin/node /usr/local/bin/node && \
    cp /tmp/node/bin/npm /usr/local/bin/npm && \
    rm -rf /tmp/node

# 📂 Copy your files into the container
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# ✅ Set permissions (use existing 'cfx' user/group: 1000:1000)
RUN chmod +x ${HOME}/initmain.mjs && \
    chown -R cfx:cfx ${HOME}

# 🌐 Expose common FXServer and txAdmin ports
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Optional: Pterodactyl panel healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD test -x ${HOME}/initmain.mjs

# 👤 Run as Pterodactyl-compatible user
USER cfx

# 🚀 Entrypoint
ENTRYPOINT ["node", "--no-warnings", "--enable-source-maps", "/home/container/initmain.mjs"]