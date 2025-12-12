#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "ℹ️  Run this from WSL. It writes files under your Windows profile."
	exit 0
fi

if ! command -v cmd.exe >/dev/null 2>&1; then
	echo "❌ cmd.exe not available; cannot resolve Windows user profile"
	exit 1
fi

WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
if [[ -z "$WIN_USER" ]]; then
	echo "❌ Could not determine Windows username"
	exit 1
fi

APPDATA_DIR="/mnt/c/Users/${WIN_USER}/AppData/Roaming/just"
CONFIG_DIR="/mnt/c/Users/${WIN_USER}/.config/just"
mkdir -p "$APPDATA_DIR" "$CONFIG_DIR"

cat >"$APPDATA_DIR/justfile" <<'JEOF'
# Windows global justfile delegating to WSL
set shell := ["powershell.exe", "-NoProfile", "-Command"]

# Add or update an env var in DOTFILES .env
# Usage: just env-add KEY:VALUE  or  just env-add KEY=VALUE
env-add KEY_VALUE:
    @wsl.exe -e bash --noprofile --norc -lc "cd ~/dotfiles && scripts/envctl.sh add '{{KEY_VALUE}}' && echo '✅ Added/updated: {{KEY_VALUE}}'"

# Remove an env var from DOTFILES .env
# Usage: just env-remove KEY
env-remove KEY:
    @wsl.exe -e bash --noprofile --norc -lc "cd ~/dotfiles && scripts/envctl.sh remove '{{KEY}}' && echo '🗑️  Removed: {{KEY}} (if present)'"

# List env vars from DOTFILES .env
env-list:
    @wsl.exe -e bash --noprofile --norc -lc "cd ~/dotfiles && scripts/envctl.sh list"
JEOF

cp -f "$APPDATA_DIR/justfile" "$CONFIG_DIR/justfile"

echo "✅ Wrote Windows global justfile to:"
echo "  - $APPDATA_DIR/justfile"
echo "  - $CONFIG_DIR/justfile"
