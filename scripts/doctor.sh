#!/usr/bin/env bash
# scripts/doctor.sh - environment diagnostic helper
set -euo pipefail

echo "Dotfiles Doctor"
echo "================"

# Basic checks
fail=0

check() {
	local label
	local cmd
	label="$1"
	cmd="$2"
	if eval "$cmd" >/dev/null 2>&1; then
		printf '✅ %s\n' "$label"
	else
		printf '❌ %s\n' "$label"
		fail=1
	fi
}

check "DOTFILES_ROOT set" "[ -n \"${DOTFILES_ROOT:-}\" ]"
check "Home writable" "[ -w \"$HOME\" ]"
check "Projects dir present" "[ -d \"${PROJECTS_ROOT:-$HOME/projects}\" ]"
check "Oh My Posh binary (optional)" "command -v oh-my-posh"

if [ "$fail" -eq 0 ]; then
	echo "All basic checks passed"
else
	echo "Some checks failed" >&2
fi
exit $fail
