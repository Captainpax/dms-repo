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

# ---------------------------------------------
# 📦 Install runtime dependencies
# ---------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash curl wget git unzip xz-utils file jq \
        libstdc++6 libgcc-s1 libc6 libcurl4 ca-certificates tree gettext && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📁 Prepare filesystem layout
# ---------------------------------------------
RUN mkdir -p ${HOME}/opt/cfx-server \
             ${HOME}/resources \
             ${HOME}/logs \
             ${HOME}/cache

# ---------------------------------------------
# 📦 Copy static build assets (scripts + fx.tar.xz + cfg)
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# ---------------------------------------------
# 🧪 Extract FiveM binary and sanity check (at build time)
# ---------------------------------------------
RUN mkdir -p ${HOME}/opt/cfx-server && \
    tar -xf ${HOME}/fx.tar.xz -C ${HOME}/opt/cfx-server && \
    if [ -d "${HOME}/opt/cfx-server/alpine/opt/cfx-server" ]; then \
      echo "[!] Flattening nested alpine structure..."; \
      cp -a ${HOME}/opt/cfx-server/alpine/opt/cfx-server/. ${HOME}/opt/cfx-server/ && \
      rm -rf ${HOME}/opt/cfx-server/alpine; \
    fi && \
    echo "[*] Sanity check on FXServer binary:" && \
    file ${HOME}/opt/cfx-server/FXServer && \
    ldd ${HOME}/opt/cfx-server/FXServer || true && \
    rm -f ${HOME}/fx.tar.xz
RUN chmod +x /home/container/opt/cfx-server/FXServer

# ---------------------------------------------
# ✅ Fix ownership and permissions
# ---------------------------------------------
RUN chmod +x ${HOME}/entrypoint.sh ${HOME}/install.sh && \
    chown -R 1000:1000 ${HOME}

# ---------------------------------------------
# 🌐 Expose ports (game & txAdmin)
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck (validates binary existence)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD ["bash", "-c", "[ -f /home/container/opt/cfx-server/FXServer ]"]

# 👤 Pterodactyl requires UID:GID 1000
USER 1000:1000

# ⛩️ Set working directory (Pterodactyl standard)
WORKDIR /home/container

# 🚀 Entrypoint script (launches runtime logic)
ENTRYPOINT ["/home/container/entrypoint.sh"]