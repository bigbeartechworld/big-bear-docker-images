FROM nextcloud:32.0.3-apache

RUN set -e; \
    apt-get update && \
    apt-get install -y libsmbclient-dev build-essential autoconf ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pecl install smbclient && \
    docker-php-ext-enable smbclient && \
    php -m | grep -q 'smbclient'
