# 🧱 Base image: Pterodactyl's Python 3.10 yolk
FROM ghcr.io/pterodactyl/yolks:python_3.10

# 👤 Become root to install dependencies and copy files
USER root

# 📂 Ensure the working directory exists
WORKDIR /home/container

# 📁 Copy the build context and stage Archipelago server files into place
COPY . /tmp/build-context/

# 🧹 Move the Archipelago tree if present, otherwise leave an empty workspace
RUN if [ -d /tmp/build-context/Archipelago ]; then \
      cp -a /tmp/build-context/Archipelago/. /home/container/; \
    else \
      echo "⚠️  Archipelago directory not found in build context; continuing with empty workspace"; \
    fi \
    && rm -rf /tmp/build-context

# 📦 Install Python dependencies if a requirements file is present
RUN if [ -f requirements.txt ]; then \
      python -m pip install --no-cache-dir -r requirements.txt; \
    else \
      echo "⚠️  requirements.txt not found, skipping dependency installation"; \
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
      '  echo "   Populate the image by copying an Archipelago/ tree into the build context." >&2' \
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
