FROM ubuntu:25.04 as dms-base
LABEL authors="AntimatterZoneLLC"
LABEL description="Base Docker Image for Darkmatter Servers (Ubuntu 25.04)"

ENV DEBIAN_FRONTEND=noninteractive

# System upgrade, essential packages installation, and cleanup
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        ca-certificates \
        tzdata \
        locales && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set up locale to UTF-8 (common default for broad compatibility)
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set default timezone to UTC (customizable in derived images)
ENV TZ=Etc/UTC
RUN ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Define working directory
WORKDIR /root
