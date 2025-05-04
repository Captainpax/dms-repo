# ---------------------------------------------
# 🧼 Base Image: Debian Slim (glibc compatible)
# ---------------------------------------------
FROM debian:bullseye-slim

# 👤 Metadata
LABEL maintainer="Antimatter Zone LLC"
LABEL org.opencontainers.image.source="https://github.com/Captainpax/dms-repo"

# ---------------------------------------------
# ⚙️ Environment
# ---------------------------------------------
ENV HOME=/home/container
WORKDIR ${HOME}
ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------
# 📦 Install dependencies
# ---------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates bash unzip jq gnupg \
    file xz-utils git gettext \
    libatomic1 libssl1.1 libv8-dev \
    libstdc++6 libcurl4 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📥 Install Node.js 23.x from NodeSource
# ---------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------
# 📥 Download FXServer archive into container
# ---------------------------------------------
RUN curl -sSL -o ${HOME}/linux.tar.xz https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/14758-36b17e986ff6393de11928a14d485c8ed053c194/fx.tar.xz

# ---------------------------------------------
# 📂 Copy project files (initmain.mjs, server.cfg, etc.)
# ---------------------------------------------
COPY dockers/games/gtav/fivem/home/container/ ${HOME}/

# ---------------------------------------------
# 📁 Ensure resources/ folder exists
# ---------------------------------------------
RUN mkdir -p ${HOME}/resources

# 👉 Optional: Add default resources here
# COPY ./default-resources/* ${HOME}/resources/

# ---------------------------------------------
# 📦 Install Node dependencies
# ---------------------------------------------
RUN npm i

# ---------------------------------------------
# ✅ Set final permissions
# ---------------------------------------------
RUN chmod +x ${HOME}/initmain.mjs && \
    groupadd -g 1000 user && useradd -u 1000 -g 1000 -d ${HOME} -s /bin/bash user && \
    chown -R user:user ${HOME}

# ---------------------------------------------
# 🌐 Expose game & txAdmin ports
# ---------------------------------------------
EXPOSE 30120/tcp 30120/udp
EXPOSE 40120/tcp 40120/udp

# 🩺 Healthcheck for Pterodactyl binary validation
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD [ "test", "-x", "/home/container/opt/cfx-server/FXServer" ]

# 👤 Run as Pterodactyl UID/GID
USER user

# 🚀 Entrypoint to run initmain
ENTRYPOINT ["node", "--no-warnings", "--enable-source-maps", "/home/container/initmain.mjs"]