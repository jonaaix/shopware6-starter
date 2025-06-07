#!/bin/bash

# s3-public-cache-control.sh
# This script sets Cache-Control headers on files uploaded to DigitalOcean Spaces
# in the last 1 hour by default – or on all files if --all is passed.
# Intended to improve **browser caching**.
#
# It sets the following header:
# Cache-Control: public, max-age=31536000, immutable
# → This tells the browser to cache the file for **1 year** (31536000 seconds).
#
# 📅 To run this script every hour via cron, add this line:
# 0 * * * * /path/to/s3-public-cache-control.sh >> /var/log/s3-public-cache-control.log 2>&1
#
# 🛠 To manually update ALL files:
# ./scripts/s3-public-cache-control.sh --all

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

CONFIG_PATH="$HOME/.s3cfg-shopware"

if [ ! -f "$CONFIG_PATH" ]; then
   echo "❌ ERROR: s3cmd config file not found at $CONFIG_PATH"
   exit 1
fi

# Load .env from project root
cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

if [ -f "$PROJECT_ROOT/.env" ]; then
  set -o allexport
  . "$PROJECT_ROOT/.env"
  set +o allexport
fi

: "${S3_BUCKET:?Missing S3_BUCKET in .env}"

# CONFIG
S3CMD="s3cmd --config $CONFIG_PATH"
BUCKET_PATH="s3://${S3_BUCKET}/prod/sw6/public/"
RUN_ALL=false

# Parse arguments
for arg in "$@"; do
   case $arg in
   --all | -a)
      RUN_ALL=true
      ;;
   esac
done

if [ "$RUN_ALL" = false ]; then
   CUTOFF=$(date -d '1 hour ago' +%Y-%m-%dT%H:%M)
   echo "📦 Mode: Updating files modified since $CUTOFF"
else
   echo "📦 Mode: Updating ALL files (no time filter)"
fi

echo "🔍 Scanning $BUCKET_PATH"

# Generate list of target files
FILE_LIST=$(mktemp)

$S3CMD ls "$BUCKET_PATH" --recursive |
   grep -v '/$' |
   while read -r line; do
      file_date=$(echo "$line" | awk '{print $1" "$2}')
      file_path=$(echo "$line" | awk '{for (i=4; i<=NF; i++) printf "%s ", $i; print ""}' | xargs)

      if [ -z "$file_path" ]; then
         continue
      fi

      if [ "$RUN_ALL" = false ]; then
         file_ts=$(date -d "$file_date" +%Y-%m-%dT%H:%M 2>/dev/null)
         if [[ "$file_ts" < "$CUTOFF" ]]; then
            continue
         fi
      fi

      echo "$file_path" >>"$FILE_LIST"
   done

echo "🚀 Modifying Cache-Control headers in parallel (10 threads)..."

cat "$FILE_LIST" | xargs -P 10 -I {} bash -c \
   "echo '🔧 Updating: {}'; $S3CMD modify '{}' --add-header='Cache-Control: public, max-age=31536000, immutable' || echo '❌ Failed: {}'"

rm "$FILE_LIST"

echo "✅ Done!"
echo ""
