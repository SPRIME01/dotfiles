#!/usr/bin/env bash
# Description: Select an active shell/profile configuration (minimal|developer|full) by writing a marker file.
# Category: setup
# Dependencies: bash
# Idempotent: yes (overwrites same selection)
# Inputs: PROFILE (arg or env), DOTFILES_PROFILE_FILE override
# Outputs: Active profile marker file
# Exit Codes: 0 success, >0 invalid profile
set -euo pipefail

PROFILE="${1:-${PROFILE:-developer}}"
VALID=(minimal developer full)
if ! printf '%s\n' "${VALID[@]}" | grep -qx "$PROFILE"; then
  echo "❌ Invalid profile: $PROFILE (valid: ${VALID[*]})" >&2
  exit 1
fi
MARKER="${DOTFILES_PROFILE_FILE:-$HOME/.dotfiles-profile}"
echo "$PROFILE" > "$MARKER"
chmod 600 "$MARKER" 2>/dev/null || true
echo "✅ Active profile set to '$PROFILE' (marker: $MARKER)"
