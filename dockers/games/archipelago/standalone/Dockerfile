# 🧱 Base image: Pterodactyl's Python 3.10 yolk
FROM ghcr.io/pterodactyl/yolks:python_3.10

# 👤 Become root to install dependencies and copy files
USER root

# 📂 Ensure the working directory exists
WORKDIR /home/container

# 🛠️ Install utilities required to download and unpack upstream releases
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tar \
      unzip; \
    rm -rf /var/lib/apt/lists/*

# 🌐 Configure source retrieval
ARG ARCHIPELAGO_SOURCE_URL="https://cloud.antimatterzone.net/s/bNZ57tEMd5downP/download"
ENV ARCHIPELAGO_SOURCE_URL="${ARCHIPELAGO_SOURCE_URL}"

# 📁 Optionally accept an overridden Archipelago tree from the build context
COPY Archipelago/ /tmp/override/Archipelago/

# 📦 Stage Archipelago server files via download or override
RUN set -eux; \
    DEST_DIR="/home/container/Archipelago"; \
    mkdir -p "${DEST_DIR}"; \
    if find /tmp/override/Archipelago -mindepth 1 -maxdepth 1 -not -name '.gitkeep' -print -quit | grep -q .; then \
      echo "📁 Detected Archipelago override in build context; copying to container."; \
      rm -rf "${DEST_DIR}"; \
      mkdir -p "${DEST_DIR}"; \
      cp -a /tmp/override/Archipelago/. "${DEST_DIR}/"; \
    else \
      echo "🌐 Downloading Archipelago sources from ${ARCHIPELAGO_SOURCE_URL}."; \
      TMP_DIR="$(mktemp -d)"; \
      ARCHIVE_PATH="${TMP_DIR}/archipelago.archive"; \
      curl -fsSL "${ARCHIPELAGO_SOURCE_URL}" -o "${ARCHIVE_PATH}"; \
      EXTRACT_DIR="${TMP_DIR}/extracted"; \
      mkdir -p "${EXTRACT_DIR}"; \
      if unzip -q "${ARCHIVE_PATH}" -d "${EXTRACT_DIR}"; then \
        :; \
      elif tar -xf "${ARCHIVE_PATH}" -C "${EXTRACT_DIR}"; then \
        :; \
      else \
        echo "❌ Failed to extract the downloaded archive. Ensure the URL points to a ZIP/TAR file or provide a local override." >&2; \
        exit 1; \
      fi; \
      SOURCE_ROOT="$(find "${EXTRACT_DIR}" -type f -name 'Archipelago.py' -printf '%h\n' | sort -u | head -n1)"; \
      if [ -z "${SOURCE_ROOT}" ]; then \
        SOURCE_ROOT="$(find "${EXTRACT_DIR}" -mindepth 1 -maxdepth 1 -type d | head -n1 || true)"; \
      fi; \
      if [ -z "${SOURCE_ROOT}" ]; then \
        echo "❌ Unable to determine Archipelago root directory from downloaded archive." >&2; \
        exit 1; \
      fi; \
      rm -rf "${DEST_DIR}"; \
      mv "${SOURCE_ROOT}" "${DEST_DIR}"; \
      rm -rf "${TMP_DIR}"; \
    fi; \
    rm -rf /tmp/override

# 📦 Install Python dependencies if a requirements file is present
RUN if [ -f /home/container/Archipelago/requirements.txt ]; then \
      python -m pip install --no-cache-dir -r /home/container/Archipelago/requirements.txt; \
    else \
      echo "⚠️  requirements.txt not found in /home/container/Archipelago, skipping dependency installation"; \
    fi

# 🛠️ Generate flexible Archipelago bootstrap scripts and ensure permissions
RUN set -eux; \
    printf '%s\n' \
      '#!/bin/bash' \
      'set -euo pipefail' \
      '' \
      'BASE_DIR="/home/container"' \
      'SERVER_DIR="${BASE_DIR}/Archipelago"' \
      '' \
      'if [ ! -d "${SERVER_DIR}" ]; then' \
      '  echo "❌ Expected Archipelago sources in ${SERVER_DIR}, but the directory is missing." >&2' \
      '  echo "   The image normally downloads them automatically during build." >&2' \
      '  echo "   Rebuild with a reachable ARCHIPELAGO_SOURCE_URL or provide an Archipelago/ override." >&2' \
      '  exit 1' \
      'fi' \
      '' \
      'cd "${SERVER_DIR}"' \
      '' \
      'if [ -f "Archipelago.py" ]; then' \
      '  exec python3 Archipelago.py "$@"' \
      'elif [ -f "ArchipelagoServer.py" ]; then' \
      '  exec python3 ArchipelagoServer.py "$@"' \
      'elif python3 -c '\''import importlib.util, sys; sys.exit(0 if importlib.util.find_spec("Archipelago") else 1)'\'' >/dev/null 2>&1; then' \
      '  exec python3 -m Archipelago "$@"' \
      'else' \
      '  echo "❌ Unable to locate an Archipelago server entrypoint." >&2' \
      '  echo "   Checked for Archipelago.py, ArchipelagoServer.py, and importable module '\''Archipelago'\''." >&2' \
      '  exit 1' \
      'fi' \
      > /home/container/StartArchipelago; \
    chmod +x /home/container/StartArchipelago; \
    ln -sf StartArchipelago /home/container/StartAP; \
    chown -R 1000:1000 /home/container

# 👤 Drop back to the container user expected by Pterodactyl
USER 1000

# 🚀 Default command to launch the Archipelago server
CMD ["./StartArchipelago"]

# 📡 Expose the Archipelago server port
EXPOSE 3333
