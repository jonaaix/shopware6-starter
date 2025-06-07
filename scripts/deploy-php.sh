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

cd "$PROJECT_ROOT"

# Functions
function git_pull() {
   echo "🔄 Pulling latest changes from Git..."
   git_pull_output=$(git pull)
   echo "$git_pull_output"
}

function restart_php() {
   echo "♻️ Restarting PHP container..."
   docker compose restart php
}

function compile_theme() {
   echo "🎨 Compiling theme (SCSS/JS)..."
   docker compose exec php bash -c "php bin/console theme:compile"
}

function clear_cache() {
   echo "🧹 Clearing cache (Twig)..."
   docker compose exec php bash -c "php bin/console cache:clear"
}

# Execution starts here
echo "🚀 Starting PHP deployment script..."

# Save current HEAD before pull
previous_head=$(git rev-parse HEAD)

echo "📦 Checking for changes in the repository..."
git_pull_output=$(git_pull)
if echo "$git_pull_output" | grep -q "up to date"; then
    echo "✅ Repository is already up to date. Deployment finished."
    exit 0
fi

# Get list of changed files
echo "🔍 Checking for changed files since last pull..."
changed_files=$(git diff --name-only "$previous_head" HEAD)

compiled=false
cleared=false

echo "🔄 Restarting PHP service..."
restart_php

if echo "$changed_files" | grep -E '\.(scss|js)$' >/dev/null; then
   echo "🎨 Detected changes in SCSS/JS files. Compiling theme..."
   compile_theme
   compiled=true
fi

if echo "$changed_files" | grep -E '\.twig$' >/dev/null; then
   echo "🧹 Detected changes in Twig files. Clearing cache..."
   clear_cache
   cleared=true
fi

if [[ "$compiled" == true || "$cleared" == true ]]; then
   echo "♻️ Restarting PHP service after changes..."
   restart_php
fi

echo "✅ Deployment finished."
