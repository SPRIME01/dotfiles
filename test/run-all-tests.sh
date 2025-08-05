#!/usr/bin/env bash
# test/run-all-tests.sh - Run all tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔬 Running all dotfiles tests..."
echo "==============================="

FAILED=0

# Run shell tests
for test_script in "$SCRIPT_DIR"/*.sh; do
    # Skip this script and framework
    if [[ "$(basename "$test_script")" == "run-all-tests.sh" ]] || \
       [[ "$(basename "$test_script")" == "framework.sh" ]]; then
        continue
    fi

    if [[ -x "$test_script" ]]; then
        echo
        echo "▶️ Running $(basename "$test_script")..."
        DOTFILES_ROOT="$REPO_ROOT" bash "$test_script" || FAILED=1
    fi
done

# Run PowerShell tests if pwsh is available
for test_script in "$SCRIPT_DIR"/*.ps1; do
    if command -v pwsh >/dev/null 2>&1; then
        echo
        echo "▶️ Running $(basename "$test_script")..."
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT" || FAILED=1
    else
        echo "⚠️ Skipping $(basename "$test_script") (pwsh not available)"
    fi
done

echo
if [[ $FAILED -eq 0 ]]; then
    echo "✅ All tests passed"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
