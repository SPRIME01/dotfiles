#!/usr/bin/env bash
# Description: Pre-flight permission auditor for sensitive dotfiles (.env, state file)
# Category: diagnostic
# Dependencies: bash, stat
# Idempotent: yes (read-only warnings)
# Exit Codes: 0 always (non-blocking)
set -euo pipefail

FILES=()
[[ -f "$HOME/.env" ]] && FILES+=("$HOME/.env")
[[ -f "$HOME/.dotfiles-state" ]] && FILES+=("$HOME/.dotfiles-state")
[[ -n "${DOTFILES_STATE_FILE:-}" && -f "${DOTFILES_STATE_FILE}" ]] && FILES+=("${DOTFILES_STATE_FILE}")

get_octal_perms() {
	local path="$1"
	# GNU stat: prints like 600
	if stat -c %a "$path" >/dev/null 2>&1; then
		stat -c %a "$path"
		return 0
	fi

	# BSD/macOS stat: prints like 0100600; take last 3 digits
	if stat -f %p "$path" >/dev/null 2>&1; then
		local raw
		raw=$(stat -f %p "$path") || return 1
		echo "${raw: -3}"
		return 0
	fi

	return 1
}

for f in "${FILES[@]}"; do
	perms=$(get_octal_perms "$f" 2>/dev/null || echo "")
	[[ -z $perms ]] && continue
	if [[ $perms != 600 && $perms != 640 ]]; then
		echo "⚠️  Insecure permissions $perms on $f (recommend 600)"
	fi
done

exit 0
