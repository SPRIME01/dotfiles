#!/usr/bin/env bash
set -e

echo "📡 Checking for updates from dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
BRANCH="main"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "❌ Dotfiles repo not found in $DOTFILES_DIR"
  exit 1
fi

cd "$DOTFILES_DIR"
git pull origin $BRANCH

echo "✅ Repo synced. Reapplying configs..."

bash "$DOTFILES_DIR/bootstrap.sh"

echo "🧼 Update complete: dotfiles refreshed from $BRANCH"
