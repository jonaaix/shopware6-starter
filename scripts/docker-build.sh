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

build_image() {
   local dockerfile_path="$1"
   local context_dir="$2"
   local image_tag="$3"

   if [ ! -f "$dockerfile_path" ]; then
      echo "❌ Error: Dockerfile not found at $dockerfile_path"
      exit 1
   fi

   echo "🐳 Building Docker image: $image_tag"
   docker build -f "$dockerfile_path" -t "$image_tag" "$context_dir"
   echo "✅ Docker image built: $image_tag"
   echo ""
}

# Build shopware AIO PHP image
build_image "$PROJECT_ROOT/shopware/docker/Dockerfile" "$PROJECT_ROOT/shopware/docker" "shopware6/php:8.3"

# Build varnish image
build_image "$PROJECT_ROOT/varnish/Dockerfile" "$PROJECT_ROOT/varnish" "shopware6/varnish"

# Build spider image
build_image "$PROJECT_ROOT/spider/Dockerfile" "$PROJECT_ROOT/spider" "shopware6/spider"

# ... build other images as needed
