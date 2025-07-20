# FROM shopware/docker-base:8.4-nginx
FROM shopware/docker-base:8.3-nginx
ARG TARGETARCH

USER root

# Install dependencies
RUN apk add --no-cache bash curl patch

# Create non-root user shopware (UID 1000), add to www-data group
RUN addgroup -g 1000 shopware \
 && adduser -D -u 1000 -G shopware -s /bin/sh shopware \
 && addgroup shopware www-data

# Copy setup scripts
COPY build/container-setup.sh /tmp/container-setup.sh
COPY build/bash-config.sh /tmp/bash-config.sh

# Run setup script
RUN chmod +x /tmp/container-setup.sh && /tmp/container-setup.sh
RUN rm /tmp/container-setup.sh /tmp/bash-config.sh

# Copy heartbeat script
COPY build/heartbeat.php /heartbeat.php

# Download and install Supercronic
RUN curl -sSL -o /usr/local/bin/supercronic https://github.com/aptible/supercronic/releases/latest/download/supercronic-linux-${TARGETARCH} \
 && chmod +x /usr/local/bin/supercronic

# Copy crontab and fix permissions
COPY build/crontab.txt /home/shopware/crontab.txt
RUN chown 1000:1000 /home/shopware/crontab.txt

# Supervisor config for Supercronic
RUN echo -e "\n[include]\nfiles = /etc/supervisor.d/*.ini" >> /etc/supervisord.conf
COPY build/supercronic-supervisord.ini /etc/supervisor.d/supercronic.ini

# Switch to user shopware
USER shopware
