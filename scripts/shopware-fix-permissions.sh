#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo "🔧 Fixing permissions for Shopware container..."

DOCKER_SERVICE="php"
TARGET_USER="root"
CMD="chown -R shopware:shopware /var/www/html"

# Execute the command in the container
docker compose exec --user "$TARGET_USER" "$DOCKER_SERVICE" bash -c "$CMD"

echo "✅ Permissions fixed successfully."
