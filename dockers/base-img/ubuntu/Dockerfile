FROM ubuntu:25.04

LABEL authors="AntimatterZoneLLC"
LABEL description="Base Docker Image for Darkmatter Servers (Ubuntu 25.04)"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV TZ=Etc/UTC

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    bash \
    sudo \
    ca-certificates \
    tzdata \
    locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Create container user (still root)
RUN useradd -m -d /home/container -s /bin/bash container

WORKDIR /home/container

# Copy entrypoint and make executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to container user
USER container
ENV USER=container HOME=/home/container

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
