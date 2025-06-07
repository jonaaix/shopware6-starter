# FROM shopware/docker-base:8.4-nginx
FROM shopware/docker-base:8.3-nginx
ARG TARGETARCH

USER root

# Install dependencies
RUN apk add --no-cache bash curl patch

# Copy setup scripts
COPY build/container-setup.sh /tmp/container-setup.sh
COPY build/bash-config.sh /tmp/bash-config.sh

# Run setup script
RUN chmod +x /tmp/container-setup.sh && /tmp/container-setup.sh
RUN rm /tmp/container-setup.sh /tmp/bash-config.sh

# Copy heartbeat script
COPY build/heartbeat.php /heartbeat.php

# Download and install Supercronic
RUN curl -sSL -o /usr/local/bin/supercronic https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-${TARGETARCH} && \
    chmod +x /usr/local/bin/supercronic

# Copy crontab and set permissions
COPY build/crontab.txt /home/www-data/crontab.txt
RUN chown www-data /home/www-data/crontab.txt

# Supervisor config for Supercronic
RUN echo -e "\n[include]\nfiles = /etc/supervisor.d/*.ini" >> /etc/supervisord.conf
COPY build/supercronic-supervisord.ini /etc/supervisor.d/supercronic.ini

USER www-data
