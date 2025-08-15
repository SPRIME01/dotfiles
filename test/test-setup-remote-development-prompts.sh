#!/usr/bin/env bash
set -euo pipefail

# This test simulates declining prompts to ensure early exit paths are safe.

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Skip if not WSL (the script requires WSL)
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "SKIP: setup-remote-development requires WSL environment"
	exit 0
fi

# Provide 'n' responses to both confirmation prompts
if [[ ! -f "$ROOT/scripts/setup-remote-development.sh" ]]; then
	echo "SKIP: scripts/setup-remote-development.sh not found"
	exit 0
fi
# Provide a single 'n' to decline the first prompt and assert early, clean exit
if ! (printf 'n\n' | bash "$ROOT/scripts/setup-remote-development.sh" >/dev/null 2>&1); then
	echo "FAIL: script failed when declining first prompt" >&2
	exit 1
fi

echo "PASS: setup-remote-development safely handles declined prompts"
