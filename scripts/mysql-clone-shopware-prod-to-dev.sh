#!/bin/bash

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

DIRNAME=$(basename "$PROJECT_ROOT")
DEV_PROJECT_DIR="${PROJECT_ROOT}-dev"
EXPORT_SCRIPT="$PROJECT_ROOT/scripts/mysql-export-shopware.sh"
IMPORT_SCRIPT="$DEV_PROJECT_DIR/scripts/mysql-import-shopware.sh"
EXPORT_DIR="$PROJECT_ROOT/file-share/export"
TARGET_IMPORT_DIR="$DEV_PROJECT_DIR/file-share/import"

# 1. Check paths
[ ! -d "$DEV_PROJECT_DIR" ] && {
   echo "❌ Dev project not found at $DEV_PROJECT_DIR"
   exit 1
}
[ ! -d "$TARGET_IMPORT_DIR" ] && {
   echo "❌ Import directory not found at $TARGET_IMPORT_DIR"
   exit 1
}
[ ! -f "$EXPORT_SCRIPT" ] && {
   echo "❌ Export script not found at $EXPORT_SCRIPT"
   exit 1
}
[ ! -f "$IMPORT_SCRIPT" ] && {
   echo "❌ Import script not found at $IMPORT_SCRIPT"
   exit 1
}

# 2. Create export from prod
echo "💾 Exporting production DB..."
bash "$EXPORT_SCRIPT"

# 3. Find latest SQL dump
LATEST_DUMP=$(ls -t "$EXPORT_DIR"/*.sql | head -n 1)
[ -z "$LATEST_DUMP" ] && {
   echo "❌ No dump file found in $EXPORT_DIR"
   exit 1
}

# 4. Copy dump to dev import directory
TARGET_DUMP="$TARGET_IMPORT_DIR/dump-prod-to-dev.sql"
cp "$LATEST_DUMP" "$TARGET_DUMP"
echo "📤 Copied $LATEST_DUMP → $TARGET_DUMP"

# 5. Import in dev
echo "📥 Importing into dev environment..."
docker compose --project-directory "$DEV_PROJECT_DIR" exec -T mysql true || {
   echo "❌ Dev mysql container not running. Start it first."
   exit 1
}

bash "$IMPORT_SCRIPT" "$TARGET_DUMP"
rm "$TARGET_DUMP"

echo "✅ Done."
echo ""
