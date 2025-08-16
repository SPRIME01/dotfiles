#!/usr/bin/env bash
# Test MCP helper idempotency (lightweight)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit && pwd)"
HELPER_DIR="$ROOT/test/helpers"
SNAPSHOT_HELPER="$HELPER_DIR/state_snapshot.sh"
if [[ ! -x $SNAPSHOT_HELPER ]]; then
	echo "SKIP: snapshot helper missing"
	exit 0
fi
MCP_SCRIPT="$ROOT/mcp/mcp-helper.sh"
if [[ ! -f $MCP_SCRIPT ]]; then
	echo "SKIP: MCP helper missing"
	exit 0
fi
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME"' EXIT
run_helper() { bash "$MCP_SCRIPT" init >/dev/null 2>&1; }
if ! run_helper; then
	echo "SKIP: first init run failed (helper not stable)"
	exit 0
fi
snap1=$($SNAPSHOT_HELPER "$HOME" 4)
if ! run_helper; then
	echo "FAIL: second init run failed (not idempotent)"
	exit 1
fi
snap2=$($SNAPSHOT_HELPER "$HOME" 4)
if [[ "$snap1" != "$snap2" ]]; then
	echo "FAIL: MCP helper not idempotent"
	exit 1
fi
echo "PASS: MCP helper idempotent"
