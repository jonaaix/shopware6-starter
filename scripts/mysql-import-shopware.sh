#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

IMPORT_DIR="$PROJECT_ROOT/file-share/import"
ENV_FILE="$PROJECT_ROOT/.env"
SERVICE_NAME="mysql"
DB_TYPE="mysql"

# Load .env
if [ -f "$ENV_FILE" ]; then
   set -o allexport
   . "$ENV_FILE"
   set +o allexport
fi

: "${DB_DATABASE:?Missing DB_DATABASE}"
: "${DB_INIT_ROOT_PASSWORD:?Missing DB_INIT_ROOT_PASSWORD}"

# Allow optional SQL file as argument
if [ -n "$1" ]; then
   FILE="$1"
   if [ ! -f "$FILE" ]; then
      echo "❌ File not found: $FILE"
      exit 1
   fi
   echo "✅ Using provided SQL file: $FILE"
   echo ""
else
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
fi

echo "🔄 Dropping and recreating database $DB_DATABASE ..."
docker compose exec -T "$SERVICE_NAME" \
   "$DB_TYPE" -uroot -p"$DB_INIT_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$DB_DATABASE\`; CREATE DATABASE \`$DB_DATABASE\`;"

echo "⚙️ Disabling foreign key checks in SQL file ..."
TMP_FILE="${FILE}.tmp"

{
  echo "SET foreign_key_checks = 0;"
  cat "$FILE"
  echo "SET foreign_key_checks = 1;"
} > "$TMP_FILE" && mv "$TMP_FILE" "$FILE"

echo "⬇️ Importing $FILE ..."
docker compose exec -T "$SERVICE_NAME" \
   "$DB_TYPE" -uroot -p"$DB_INIT_ROOT_PASSWORD" "$DB_DATABASE" <"$FILE"

echo "✅ Import finished."
echo ""
