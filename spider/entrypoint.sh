#!/bin/sh

set -e

trap 'echo "STOP signal received..."; exit 0' TERM

echo "============================"
echo "===  NODE SPIDER started ==="
echo "============================"

if [ ! -f "/app/sitemaps.yaml" ]; then
  echo "❌ ERROR: /app/sitemaps.yaml not found"
  exit 1
fi

while true; do
  node /app/sitemap_spider.js || exit 1
done
