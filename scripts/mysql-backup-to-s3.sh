#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
EXPORT_SCRIPT_SHOPWARE="$PROJECT_ROOT/scripts/mysql-export-shopware.sh"
EXPORT_SCRIPT_WORDPRESS="$PROJECT_ROOT/scripts/mysql-export-wordpress.sh"
EXPORT_DIR="$PROJECT_ROOT/file-share/export"

# Load .env
if [ -f "$PROJECT_ROOT/.env" ]; then
   set -o allexport
   . "$PROJECT_ROOT/.env"
   set +o allexport
fi

: "${S3_BACKUP_BUCKET:?Missing S3_BACKUP_BUCKET in .env}"

S3_BUCKET="s3://${S3_BACKUP_BUCKET}"
S3CMD="s3cmd --config $HOME/.s3cfg-shopware"

# 1. Run Shopware export
echo "🔄 Exporting Shopware DB..."
bash "$EXPORT_SCRIPT_SHOPWARE"

# 2. Run WordPress export
echo "🔄 Exporting WordPress DB..."
bash "$EXPORT_SCRIPT_WORDPRESS"

# 3. Find latest dump files
LATEST_SHOPWARE_DUMP=$(ls -t "$EXPORT_DIR"/shopware*backup*.sql 2>/dev/null | head -n1)
LATEST_WP_DUMP=$(ls -t "$EXPORT_DIR"/wordpress*backup*.sql 2>/dev/null | head -n1)

if [ ! -f "$LATEST_SHOPWARE_DUMP" ] || [ ! -f "$LATEST_WP_DUMP" ]; then
   echo "❌ One or both SQL dumps not found."
   exit 1
fi

# 4. Create S3 destination path
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
S3_PATH="$S3_BUCKET/$TIMESTAMP"

echo "📤 Uploading backups to $S3_PATH..."

$S3CMD put "$LATEST_SHOPWARE_DUMP" "$S3_PATH/" --acl-private
$S3CMD put "$LATEST_WP_DUMP" "$S3_PATH/" --acl-private

echo "✅ Upload completed."
echo ""

# Delete local dumps after upload
echo "🗑️ Cleaning up local dumps..."
echo "Removed: $LATEST_SHOPWARE_DUMP"
echo "Removed: $LATEST_WP_DUMP"
rm -f "$LATEST_SHOPWARE_DUMP" "$LATEST_WP_DUMP"

# 5. Clean old backups
bash "$PROJECT_ROOT/scripts/s3-clean-backups.sh"

echo "🎉 Backup to S3 completed successfully."
