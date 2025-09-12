#!/usr/bin/env bash
# test-preflight.sh - Regression tests for ssh-agent-bridge/preflight.sh
set -uo pipefail
echo "[preflight-test] start"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/framework.sh"

if ! grep -qi microsoft /proc/version 2>/dev/null && [ -z "${WSL_DISTRO_NAME:-}" ]; then
  echo "SKIP: preflight tests (not WSL)"
  exit 0
fi
# Basic execution (non-strict) should always exit 0 even with WARN/FAIL.
set +e
OUTPUT=$(bash "$REPO_ROOT/ssh-agent-bridge/preflight.sh" 2>&1)
CODE=$?
set -e
echo "[preflight-test] ran preflight EC=$CODE"

test_assert "Preflight exits 0 non-strict" "echo $CODE" "0"

echo "[preflight-test] asserting sections"

test_assert_contains "Preflight shows Environment section" "$OUTPUT" "== Environment =="

test_assert_contains "Preflight shows Manifest section" "$OUTPUT" "== Manifest =="

test_assert_contains "Preflight shows Public key section" "$OUTPUT" "== Public key =="

test_assert_contains "Preflight shows Agent section" "$OUTPUT" "== Agent =="

test_assert_contains "Preflight shows Shell init section" "$OUTPUT" "== Shell init =="

test_assert_contains "Preflight shows Hosts section" "$OUTPUT" "== Hosts =="

# JSON mode sanity
JSON_RAW=$(bash "$REPO_ROOT/ssh-agent-bridge/preflight.sh" --json 2>/dev/null)
JSON_OUTPUT=$(printf '%s\n' "$JSON_RAW" | awk 'BEGIN{found=""} /^\{/ {found=$0} END{print found}')
test_assert_matches "JSON output structure valid" "$JSON_OUTPUT" '\{"pass":[0-9]+,"warn":[0-9]+,"fail":[0-9]+,"strict":[01],"advice":\[.*\]\}'

echo "[preflight-test] before summary"
if test_summary; then
  echo "✅ preflight tests complete"
  exit 0
else
  exit 1
fi
