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

# 🛠️ Generate the StartAP bootstrap script and ensure permissions
RUN printf '#!/bin/bash\nset -euo pipefail\ncd /home/container\nexec python3 ArchipelagoServer.py "$@"\n' > /home/container/StartAP \
    && chmod +x /home/container/StartAP \
    && chown -R 1000:1000 /home/container

# 👤 Drop back to the container user expected by Pterodactyl
USER 1000

# 🚀 Default command to launch the Archipelago server
CMD ["./StartAP"]

# 📡 Expose the Archipelago server port
EXPOSE 3333
