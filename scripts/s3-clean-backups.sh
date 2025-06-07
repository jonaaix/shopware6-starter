#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

# Load .env from project root (relative to script)
cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

if [ -f "$PROJECT_ROOT/.env" ]; then
   set -o allexport
   . "$PROJECT_ROOT/.env"
   set +o allexport
fi

: "${S3_BACKUP_BUCKET:?Missing S3_BACKUP_BUCKET in .env}"

S3_BUCKET="s3://${S3_BACKUP_BUCKET}"
S3CMD="s3cmd --config $HOME/.s3cfg-shopware"
RETENTION_DAYS=30

echo "🧹 Cleaning up old S3 backups in $S3_BUCKET (keeping last $RETENTION_DAYS days)..."

CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%s)

# Get all top-level "folders" (prefixes)
$S3CMD ls "$S3_BUCKET/" | while read -r line; do
   DATE_STR=$(echo "$line" | awk '{print $1 " " $2}')
   DIR_NAME=$(echo "$line" | awk '{print $4}')
   DIR_NAME=${DIR_NAME%/} # Remove trailing slash

   # Parse date of backup folder
   DIR_DATE=$(date -d "$DATE_STR" +%s 2>/dev/null || true)
   if [ -z "$DIR_DATE" ]; then
      continue
   fi

   if [ "$DIR_DATE" -lt "$CUTOFF_DATE" ]; then
      echo "🗑️  Deleting old backup: $DIR_NAME"
      $S3CMD del --recursive "$DIR_NAME/"
   fi
done

echo "✅ S3 cleanup complete."
echo ""
