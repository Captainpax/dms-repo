# Rust Dedicated Server with optional Oxide/uMod layering
# Base on Debian Bookworm yolk for compatibility with Pterodactyl-style environments
FROM ghcr.io/pterodactyl/yolks:debian_bookworm

USER root

# Build-time toggles
ARG INCLUDE_OXIDE=true
ARG OXIDE_DOWNLOAD_URL=https://umod.org/games/rust/download
ARG RUST_APP_ID=258550

# Common runtime defaults
ENV RUST_SERVER_IP=0.0.0.0 \
    RUST_SERVER_PORT=28015 \
    RUST_SERVER_QUERY_PORT=28015 \
    RUST_RCON_IP=0.0.0.0 \
    RUST_RCON_PORT=28016 \
    RUST_RCON_PASSWORD=changeme \
    RUST_RCON_WEB=1 \
    RUST_SERVER_IDENTITY=dms-rust \
    RUST_SERVER_SEED=1337 \
    RUST_SERVER_WORLDSIZE=3500 \
    RUST_SERVER_MAXPLAYERS=50 \
    RUST_SERVER_NAME="DarkMatter Rust" \
    RUST_SERVER_DESCRIPTION="Rust dedicated server" \
    RUST_SERVER_SAVE_INTERVAL=300 \
    RUST_ADDITIONAL_ARGS=""

# Install dependencies and SteamCMD
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV STEAMCMDDIR=/home/steamcmd
RUN mkdir -p "$STEAMCMDDIR" /home/container/server && \
    chown -R 1000:1000 /home/container "$STEAMCMDDIR"

WORKDIR /home/container

# Fetch SteamCMD
RUN cd "$STEAMCMDDIR" && \
    curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz

# Install Rust Dedicated Server
RUN "$STEAMCMDDIR/steamcmd.sh" +login anonymous +force_install_dir /home/container/server +app_update "$RUST_APP_ID" validate +quit

# Optionally layer in Oxide/uMod
RUN if [ "$INCLUDE_OXIDE" = "true" ]; then \
      echo "Downloading Oxide/uMod from $OXIDE_DOWNLOAD_URL"; \
      curl -fSL "$OXIDE_DOWNLOAD_URL" -o /tmp/oxide.zip; \
      unzip -o /tmp/oxide.zip -d /home/container/server; \
      rm /tmp/oxide.zip; \
    else \
      echo "Skipping Oxide/uMod download"; \
    fi

# Entrypoint script
COPY start.sh /home/container/start.sh
RUN chmod +x /home/container/start.sh && \
    chown -R 1000:1000 /home/container

USER 1000

VOLUME ["/home/container/server", "/home/container/server/server", "/home/container/server/logs"]

WORKDIR /home/container/server

EXPOSE 28015/tcp 28015/udp 28016/tcp 28016/udp

CMD ["/home/container/start.sh"]
