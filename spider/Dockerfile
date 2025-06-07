FROM python:3.11-alpine

# System-Abhängigkeiten
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev

# Scrapy direkt installieren
RUN pip install --no-cache-dir scrapy

# Arbeitsverzeichnis
WORKDIR /app

# Spider Code
COPY sitemap_spider.py .

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
