#!/usr/bin/env bash
# Description: Pre-flight permission auditor for sensitive dotfiles (.env, state file) enforcing 600 recommendation.
# Category: diagnostic
# Dependencies: bash, stat
# Idempotent: yes (read-only warnings)
# Inputs: DOTFILES_STATE_FILE, PROJECTS_ROOT, working directory
# Outputs: Warning lines for any insecure permissions
# Exit Codes: 0 always (non-blocking)
set -euo pipefail

FILES=()
[[ -f "$HOME/.env" ]] && FILES+=("$HOME/.env")
[[ -f "$HOME/.dotfiles-state" ]] && FILES+=("$HOME/.dotfiles-state")
[[ -n "${DOTFILES_STATE_FILE:-}" && -f "${DOTFILES_STATE_FILE}" ]] && FILES+=("${DOTFILES_STATE_FILE}")

for f in "${FILES[@]}"; do
  perms=$(stat -c %a "$f" 2>/dev/null || echo "")
  [[ -z $perms ]] && continue
  if [[ $perms != 600 && $perms != 640 ]]; then
    echo "⚠️  Insecure permissions $perms on $f (recommend 600)"
  fi
 done

exit 0
