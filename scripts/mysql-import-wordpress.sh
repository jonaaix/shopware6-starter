#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

# Change to the script directory
cd "$(dirname "$0")"

# Resolve Git project root
if ! PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
   echo "❌ Error: Script is not inside a Git repository."
   exit 1
fi

IMPORT_DIR="$PROJECT_ROOT/file-share/import"
ENV_FILE="$PROJECT_ROOT/.env"
SERVICE_NAME="mysql"
DB_TYPE="mysql"

# Load .env if it exists
if [ -f "$ENV_FILE" ]; then
   set -o allexport
   . "$ENV_FILE"
   set +o allexport
fi

# Check required env vars
: "${WP_DB_DATABASE:?Missing WP_DB_DATABASE}"
: "${DB_INIT_ROOT_PASSWORD:?Missing DB_INIT_ROOT_PASSWORD}"

# Find SQL files
echo "📂 Available SQL files in $IMPORT_DIR:"
SQL_FILES=$(find "$IMPORT_DIR" -type f -name "*.sql")
if [ -z "$SQL_FILES" ]; then
   echo "❌ No SQL files found in $IMPORT_DIR"
   exit 1
fi

select FILE in $SQL_FILES; do
   if [ -n "$FILE" ]; then
      echo "✅ Selected: $FILE"
      echo ""
      break
   fi
done

# Drop and recreate DB as root
echo "🔄 Dropping and recreating database $WP_DB_DATABASE ..."
docker compose exec -T "$SERVICE_NAME" \
   "$DB_TYPE" -uroot -p"$DB_INIT_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$WP_DB_DATABASE\`; CREATE DATABASE \`$WP_DB_DATABASE\`;"

echo "⚙️ Disabling foreign key checks in SQL file ..."
TMP_FILE="${FILE}.tmp"

{
  echo "SET foreign_key_checks = 0;"
  cat "$FILE"
  echo "SET foreign_key_checks = 1;"
} > "$TMP_FILE" && mv "$TMP_FILE" "$FILE"

# Import as root
echo "⬇️ Importing $FILE as root ..."
docker compose exec -T "$SERVICE_NAME" \
   "$DB_TYPE" -uroot -p"$DB_INIT_ROOT_PASSWORD" "$WP_DB_DATABASE" <"$FILE"

echo "✅ Import finished."
echo ""
