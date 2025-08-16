#!/usr/bin/env bash
# Ensure doctor runs without crashing; output is informational
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_ROOT="$REPO_ROOT" REPO_ROOT="$REPO_ROOT" bash "$REPO_ROOT/scripts/doctor.sh" >/dev/null || {
	echo "❌ doctor failed"
	exit 1
}

echo "✅ doctor ran successfully"
