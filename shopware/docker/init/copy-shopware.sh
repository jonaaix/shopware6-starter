#!/bin/sh

TARGET_DIR="/var/www/html"
INIT_DIR="/z-init-data/shopware6-6"
MARKER_FILE="$TARGET_DIR/.z-installed"

if [ -f "$MARKER_FILE" ]; then
  echo "Init already completed – skipping copy step."
  echo "Initialized from: $(cat "$MARKER_FILE")"
else
   echo "Initializing data from $INIT_DIR to $TARGET_DIR ..."

   # Copy all files including hidden ones, but do not overwrite existing files
   rsync -av --ignore-existing "$INIT_DIR"/ "$TARGET_DIR"/

   echo "$INIT_DIR" > "$MARKER_FILE"

   mkdir -p "$TARGET_DIR"/custom/plugins
   mkdir -p "$TARGET_DIR"/custom/static-plugins

   composer update
   composer install --no-dev

   echo ""
   echo "IGNORE THE ERROR: Base table or view not found..."
   echo ""

   chown -R shopware:shopware "$TARGET_DIR"

   echo "Initialization finished."
fi
