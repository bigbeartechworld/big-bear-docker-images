FROM nextcloud:30.0.0-apache

RUN apt-get update && \
    apt-get install -y libsmbclient-dev && \
    pecl install smbclient && \
    docker-php-ext-enable smbclient

RUN echo "extension=smbclient.so" > /usr/local/etc/php/conf.d/docker-php-ext-smbclient.ini
