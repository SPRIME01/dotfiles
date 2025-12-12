#!/usr/bin/env bash
# Auto-sync .env changes to systemd if file has been modified
# Add to shell startup to keep systemd env in sync

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
ENV_FILE="$DOTFILES_ROOT/.env"
SYNC_MARKER="$HOME/.cache/dotfiles-env-sync"

# Create cache dir if needed
mkdir -p "$(dirname "$SYNC_MARKER")"

# Check if .env exists
[[ -f "$ENV_FILE" ]] || return 0

# Get current modification time
current_mtime=$(stat -c %Y "$ENV_FILE" 2>/dev/null || stat -f %m "$ENV_FILE" 2>/dev/null || echo "0")

# Get last sync time
last_sync=$(cat "$SYNC_MARKER" 2>/dev/null || echo "0")

# If .env is newer than last sync, sync it
if [[ "$current_mtime" -gt "$last_sync" ]]; then
	echo "📝 Detected changes in .env, syncing to systemd..."
	if bash "$DOTFILES_ROOT/scripts/export-to-systemd-env.sh" "$ENV_FILE" 2>/dev/null; then
		echo "$current_mtime" >"$SYNC_MARKER"
		echo "✓ Environment synced. Restart VS Code to pick up changes."
	fi
fi
