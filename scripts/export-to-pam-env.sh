#!/usr/bin/env bash
# Create/update ~/.pam_environment with dotfiles environment variables
# This loads variables at login for ALL applications

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
ENV_FILE="${1:-$DOTFILES_ROOT/.env}"
PAM_ENV="$HOME/.pam_environment"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: Environment file not found: $ENV_FILE" >&2
    exit 1
fi

# Backup existing .pam_environment
if [[ -f "$PAM_ENV" ]]; then
    cp "$PAM_ENV" "${PAM_ENV}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Backed up existing $PAM_ENV"
fi

# Create header
cat > "$PAM_ENV" << 'EOF'
# PAM Environment - Auto-generated from dotfiles
# Variables here are available to ALL applications at login
# Generated: $(date)

EOF

echo "Writing variables from $ENV_FILE to $PAM_ENV..."

# Read each line and convert to PAM format
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

    # Write in PAM format: KEY DEFAULT=value
    echo "${key} DEFAULT=${value}" >> "$PAM_ENV"
    echo "  ✓ ${key}"
done < <(grep -v '^[[:space:]]*#' "$ENV_FILE" | grep -v '^$')

echo ""
echo "Done! Log out and log back in for changes to take effect."
echo ""
echo "Note: .pam_environment is deprecated on some newer systems."
echo "If this doesn't work, use the systemd option instead:"
echo "  bash scripts/export-to-systemd-env.sh"
