FROM nextcloud:33.0.5-apache

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -e; \
    apt-get update && \
    apt-get install -y libsmbclient-dev build-essential autoconf ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pecl install smbclient && \
    docker-php-ext-enable smbclient && \
    php -m | grep -q 'smbclient'

# OCI Image Labels
ARG VERSION
ARG REVISION
LABEL org.opencontainers.image.title="Big Bear Nextcloud with SMBClient" \
      org.opencontainers.image.description="Nextcloud file sharing platform with SMBClient support for Windows shares" \
      org.opencontainers.image.url="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.source="https://github.com/bigbeartechworld/big-bear-docker-images" \
      org.opencontainers.image.vendor="BigBearTechWorld" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}"
