#!/usr/bin/env bash
set -euo pipefail

# Run all test scripts in the test/ directory.  This helper ensures
# consistent test execution regardless of your current working directory.
# Tests should exit with status code 0 on success and non‑zero on failure.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEST_DIR="$REPO_ROOT/test"

echo "🔬 Running dotfiles test suite..."

if [ ! -d "$TEST_DIR" ]; then
  echo "No test directory found at $TEST_DIR" >&2
  exit 1
fi

FAILED=0

for test_script in "$TEST_DIR"/*.sh; do
  if [ -x "$test_script" ]; then
    echo "▶️  Running $(basename "$test_script")..."
    DOTFILES_ROOT="$REPO_ROOT" bash "$test_script" || FAILED=1
  fi
done

# Run PowerShell tests if pwsh is available
for test_script in "$TEST_DIR"/*.ps1; do
  if command -v pwsh >/dev/null 2>&1; then
    echo "▶️  Running $(basename "$test_script")..."
    pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT" || FAILED=1
  else
    echo "⚠️  Skipping $(basename "$test_script") (pwsh not available)"
  fi
done

if [ "$FAILED" -eq 0 ]; then
  echo "✅ All tests passed"
else
  echo "❌ Some tests failed"
  exit 1
fi