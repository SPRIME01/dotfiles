#!/usr/bin/env bash
# Test MCP helper idempotency (lightweight)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER_DIR="$ROOT/test/helpers"
SNAPSHOT_HELPER="$HELPER_DIR/state_snapshot.sh"
if [[ ! -x $SNAPSHOT_HELPER ]]; then echo "SKIP: snapshot helper missing"; exit 0; fi
MCP_SCRIPT="$ROOT/mcp/mcp-helper.sh"
if [[ ! -f $MCP_SCRIPT ]]; then echo "SKIP: MCP helper missing"; exit 0; fi
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
run_helper() { bash "$MCP_SCRIPT" init >/dev/null 2>&1 || true; }
run_helper || true
snap1=$($SNAPSHOT_HELPER "$HOME" 4)
run_helper || true
snap2=$($SNAPSHOT_HELPER "$HOME" 4)
if [[ "$snap1" != "$snap2" ]]; then echo "FAIL: MCP helper not idempotent"; exit 1; fi
echo "PASS: MCP helper idempotent"
