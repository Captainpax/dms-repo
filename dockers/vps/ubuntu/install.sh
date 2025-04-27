#!/bin/bash

echo "[*] Starting VPS container initialization..."

# Load environment variables from Pterodactyl
ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASS=${ADMIN_PASS:-adminpass}
SSH_PORT=${SSH_PORT:-2222}
TIMEZONE=${TIMEZONE:-Etc/UTC}

# Set timezone
echo "[*] Configuring timezone to $TIMEZONE..."
ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# Configure SSH server
echo "[*] Configuring SSH to use port $SSH_PORT..."
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Setup firewall (UFW)
echo "[*] Setting firewall rules..."
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT"/tcp
echo "y" | ufw enable

# Create admin user
echo "[*] Creating user '$ADMIN_USER'..."
useradd -m -s /bin/bash -G sudo "$ADMIN_USER"
echo "$ADMIN_USER:$ADMIN_PASS" | chpasswd

# Secure root account
passwd -l root

echo "[*] Initialization complete!"
