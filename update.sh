#!/usr/bin/env bash
# Description: Safe update workflow for dotfiles (stash local changes, pull, re-bootstrap, restore stash).
# Category: maintenance
# Dependencies: git, bash
# Idempotent: yes (re-runnable; only pulls latest changes)
# Inputs: DOTFILES_DIR (defaults to $HOME/dotfiles), BRANCH (default main)
# Outputs: Updated repository, possibly restored local changes
# Exit Codes: 0 success, 1 missing repo, >1 git errors
set -euo pipefail

echo "📡 Checking for updates from dotfiles..."

DOTFILES_DIR="$HOME/dotfiles"
BRANCH="main"

if [ ! -d "$DOTFILES_DIR/.git" ]; then
	echo "❌ Dotfiles repo not found in $DOTFILES_DIR"
	exit 1
fi

# Preserve the current branch name for safety
CURRENT_BRANCH=$(git -C "$DOTFILES_DIR" rev-parse --abbrev-ref HEAD)

# Optionally stash uncommitted changes before pulling.  This prevents merge
# conflicts if you have local modifications.  The stash will be reapplied
# after the update completes.
STASHED=0
cd "$DOTFILES_DIR"
if ! git diff-index --quiet HEAD --; then
	echo "🔄 Uncommitted changes detected; stashing before update..."
	git stash push -u -m "auto-stash-before-update-$(date +%Y%m%d%H%M%S)"
	STASHED=1
fi

git pull origin $BRANCH

echo "✅ Repo synced. Reapplying configs..."

bash "$DOTFILES_DIR/bootstrap.sh"

# Reapply any stashed changes after updating
if [ "$STASHED" -eq 1 ]; then
	echo "🔁 Restoring your local changes from the stash..."
	git stash pop || true
fi

echo "🧼 Update complete: dotfiles refreshed from $BRANCH"
