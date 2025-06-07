#!/bin/sh

# s3-sync-prod-to-dev.sh
# This script syncs files from the "prod" environment to the "dev" environment
# in DigitalOcean Spaces (via Rclone), maintaining separate handling for
# `public` and `private` directories.
#
# 🪄 It sets appropriate S3 ACLs:
# - public directory → public-read
# - private directory → private
#
# 🔁 The sync uses:
# - `--delete-excluded` to remove files in dev that no longer exist in prod.
# - `--transfers` and `--checkers` tuned for high throughput.
#
# 🛠 To run this regularly via cron, add a line like:
# 0 * * * * /path/to/s3-sync-prod-to-dev.sh >> /var/log/s3-sync-prod-to-dev.log 2>&1
#
# 🚀 Usage:
# ./scripts/s3-sync-prod-to-dev.sh

set -e
trap 'echo "⛔️ Script interrupted."; exit 130' INT

cd "$(dirname "$0")"
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Load .env
if [ -f "$PROJECT_ROOT/.env" ]; then
   set -o allexport
   . "$PROJECT_ROOT/.env"
   set +o allexport
fi

: "${S3_BUCKET:?Missing S3_BUCKET in .env}"

for dir in public private; do
   visibility=public-read
   if [ "$dir" = "private" ]; then
      visibility=private
   fi

   rclone sync "shopware:${S3_BUCKET}/prod/sw6/$dir" "shopware:${S3_BUCKET}/dev/sw6/$dir" --delete-excluded --progress --transfers 32 --checkers 64 --s3-acl="$visibility"
done

echo "✅ Sync completed."
echo ""
