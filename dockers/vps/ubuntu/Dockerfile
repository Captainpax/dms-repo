FROM captainpax/dms-base:latest
LABEL authors="AntimatterZoneLLC"
LABEL description="VPS optimized Ubuntu container by AntimatterZoneLLC"

ENV DEBIAN_FRONTEND=noninteractive

# Install only VPS-specific essential tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        sudo \
        nano \
        ufw && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Basic SSH setup (secured further by install script)
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Expose default SSH port (customizable via install.sh later)
EXPOSE 22

# Copy and execute VPS-specific setup script
COPY vps/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh && /tmp/install.sh

# Set the container entry point
CMD ["/usr/sbin/sshd", "-D"]
