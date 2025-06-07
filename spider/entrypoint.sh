#!/bin/sh

set -e

trap 'echo "STOP signal received..."; exit 0' TERM

echo "============================"
echo "===    SPIDER started    ==="
echo "============================"

if [ -z "${SITEMAP_URL}" ]; then
  echo "❌ ERROR: SITEMAP_URL environment variable is not set"
  exit 1
fi

if [ -z "${SITEMAP_DOMAIN}" ]; then
  echo "❌ ERROR: SITEMAP_DOMAIN environment variable is not set"
  exit 1
fi

while true; do
  SITEMAP_DOMAIN="${SITEMAP_DOMAIN}" scrapy runspider /app/sitemap_spider.py || exit 1
done
