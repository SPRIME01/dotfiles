#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$REPO_ROOT/scripts/doctor.sh" ]]; then
	echo "SKIP: scripts/doctor.sh not found"
	exit 0
fi

DOTFILES_ROOT="$REPO_ROOT" bash "$REPO_ROOT/scripts/doctor.sh" --quick >/dev/null 2>&1 || {
	echo "❌ doctor --quick failed"
	exit 1
}
DOTFILES_ROOT="$REPO_ROOT" bash "$REPO_ROOT/scripts/doctor.sh" --verbose >/dev/null 2>&1 || {
	echo "❌ doctor --verbose failed"
	exit 1
}

echo "✅ doctor flags executed successfully"
