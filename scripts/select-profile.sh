#!/usr/bin/env bash
# Description: Select an active shell/profile configuration (minimal|developer|full) by writing a marker file.
# Category: setup
# Dependencies: bash
# Idempotent: yes (overwrites same selection)
# Inputs: PROFILE (arg or env), DOTFILES_PROFILE_FILE override
# Outputs: Active profile marker file
# Exit Codes: 0 success, >0 invalid profile
set -euo pipefail

input="${1:-}"
# Fallback order: arg > DOTFILES_PROFILE (preferred) > PROFILE (legacy) > developer
PROFILE="${input:-${DOTFILES_PROFILE:-${PROFILE:-developer}}}"
VALID=(minimal developer full)
if ! printf '%s\n' "${VALID[@]}" | grep -qx "$PROFILE"; then
  echo "❌ Invalid profile: $PROFILE (valid: ${VALID[*]})" >&2
MARKER="${DOTFILES_PROFILE_FILE:-$HOME/.dotfiles-profile}"
mkdir -p "$(dirname "$MARKER")"
tmp="${MARKER}.tmp.$$"
printf '%s\n' "$PROFILE" > "$tmp"
chmod 600 "$tmp" 2>/dev/null || true
mv "$tmp" "$MARKER"
echo "✅ Active profile set to '$PROFILE' (marker: $MARKER)"
echo "$PROFILE" > "$MARKER"
chmod 600 "$MARKER" 2>/dev/null || true
echo "✅ Active profile set to '$PROFILE' (marker: $MARKER)"
