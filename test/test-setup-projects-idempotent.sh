#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TEST_DIR/.." && pwd)"

# Simulate run (non-WSL to skip Windows integration) by unsetting WSL_DISTRO_NAME
unset WSL_DISTRO_NAME || true

# Prepare temp HOME
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME"' EXIT

SCRIPT="$ROOT/scripts/setup-projects-idempotent.sh"
HELPER="$ROOT/test/helpers/state_snapshot.sh"
if [[ ! -f "$SCRIPT" ]]; then
	echo "FAIL: setup-projects-idempotent script missing"
	exit 1
fi
if [[ ! -x "$HELPER" ]]; then
	echo "FAIL: snapshot helper missing or not executable"
	exit 1
fi
# Use isolated projects root
export PROJECTS_ROOT="$HOME/projects"

bash "$SCRIPT" >/dev/null || {
	echo "FAIL: first run errored"
	exit 1
}
[[ -d "$PROJECTS_ROOT" ]] || {
	echo "FAIL: projects directory not created"
	exit 1
}
snap1=$($HELPER "$PROJECTS_ROOT" 6)
bash "$SCRIPT" >/dev/null || {
	echo "FAIL: second run errored"
	exit 1
}
snap2=$($HELPER "$PROJECTS_ROOT" 6)
if [[ "$snap1" != "$snap2" ]]; then
	echo "FAIL: projects setup not idempotent"
	exit 1
fi
echo "PASS: setup-projects-idempotent idempotent behavior confirmed"
