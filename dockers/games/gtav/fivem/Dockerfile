# 🧱 Base image with FXServer
FROM routmoute/fxserver:recommended

# 🧰 Install Node.js and npm from Alpine packages
RUN apk add --no-cache nodejs npm

# 📂 Copy project files into container
COPY dockers/games/gtav/fivem/home/container/ /home/container/

# 📦 Run npm install if package.json is present
RUN [ -f /home/container/package.json ] && \
    npm --prefix /home/container install --omit=dev || \
    echo "⚠️  Skipping npm install (no package.json found)"

# 🔐 Set permissions (allow chown to fail on some host FS like Windows)
RUN chmod +x /home/container/initmain.mjs && \
    chown -R cfx:cfx /home/container || \
    echo "⚠️  chown failed (possibly due to Docker volume bind permissions)"

# 👤 Switch to non-root user required by Pterodactyl
USER cfx

# 🚀 Default startup command
CMD ["node", "--no-warnings", "--enable-source-maps", "/home/container/initmain.mjs"]
