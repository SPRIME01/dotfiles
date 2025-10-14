#!/usr/bin/env bash
# Export dotfiles environment variables to systemd user environment
# This makes them available to ALL graphical applications including VS Code

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
ENV_FILE="${1:-$DOTFILES_ROOT/.env}"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file not found: $ENV_FILE" >&2
    exit 1
fi

echo "Exporting variables from $ENV_FILE to systemd user environment..."

# Read each line from .env and export to systemd
while IFS= read -r line; do
    # Skip blank lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Skip lines without =
    [[ "$line" =~ = ]] || continue

    # Extract key and value
    IFS='=' read -r key value <<<"$line"
    key="$(echo "$key" | xargs)"
    value="$(echo "$value" | xargs)"

    # Remove quotes if present
    if [[ "$value" =~ ^\".*\"$ || "$value" =~ ^\'.*\'$ ]]; then
        value="${value:1:-1}"
    fi

    # Export to systemd
    systemctl --user set-environment "${key}=${value}"
    echo "  ✓ ${key}=${value:0:20}..." # Show first 20 chars for security
done < <(grep -v '^[[:space:]]*#' "$ENV_FILE" | grep -v '^$')

echo ""
echo "Done! Restart VS Code for changes to take effect."
echo "To verify: systemctl --user show-environment | grep SMITHERY"
