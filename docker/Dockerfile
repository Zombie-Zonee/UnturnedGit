FROM ubuntu:26.04

LABEL maintainer="zombiezone <tonisls@protonmail.com>"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        jq \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6 \
        libc6-dev \
        libgl1 \
        libxcursor1 \
        libxrandr2 \
        unzip \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -u 988 -d /home/container -m container

USER container
ENV USER=container
ENV HOME=/home/container

WORKDIR /home/container

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./repo-sync.sh /repo-sync.sh

RUN chmod 755 /entrypoint.sh /repo-sync.sh

CMD ["/bin/bash", "/entrypoint.sh"]
