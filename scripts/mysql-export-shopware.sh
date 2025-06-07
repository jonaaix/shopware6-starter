#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

# Change to script directory
cd "$(dirname "$0")"

# Resolve project root via Git
if ! PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
   echo "❌ Error: Script is not inside a Git repository."
   exit 1
fi

EXPORT_DIR="$PROJECT_ROOT/file-share/export"
ENV_FILE="$PROJECT_ROOT/.env"
SERVICE_NAME="mysql"

# Load .env if available
if [ -f "$ENV_FILE" ]; then
   set -o allexport
   . "$ENV_FILE"
   set +o allexport
fi

# Check required env vars
: "${DB_DATABASE:?Missing DB_DATABASE}"
: "${DB_INIT_ROOT_PASSWORD:?Missing DB_INIT_ROOT_PASSWORD}"

# Ensure export directory exists
mkdir -p "$EXPORT_DIR"

# Generate timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
EXPORT_FILE="$EXPORT_DIR/${DB_DATABASE}_backup_$TIMESTAMP.sql"

# Dump the database
echo "💾 Creating database dump of $DB_DATABASE..."
docker compose exec -T "$SERVICE_NAME" \
   mysqldump -uroot -p"$DB_INIT_ROOT_PASSWORD" "$DB_DATABASE" >"$EXPORT_FILE"

echo "✅ Dump completed: $EXPORT_FILE"
echo ""
