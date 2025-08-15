#!/usr/bin/env bash
# test/run-all-tests.sh - Run all tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔬 Running all dotfiles tests..."
echo "==============================="

FAILED=0
TOTAL=0
PASSED=0
SKIPPED=0
FAIL_LIST=()

# Run shell tests
# Run shell tests
if compgen -G "$SCRIPT_DIR/test-*.sh" > /dev/null; then
  for test_script in "$SCRIPT_DIR"/test-*.sh; do
    base="$(basename "$test_script")"
    # Skip this script and framework
    if [[ "$base" == "run-all-tests.sh" || "$base" == "framework.sh" ]]; then
      continue
    fi
    echo
    set +e
    output="$(DOTFILES_ROOT="$REPO_ROOT" bash "$test_script" 2>&1)"
    exit_code=$?
    set -e
    echo "$output"
    if grep -Eq '^[[:space:]]*SKIP:' <<<"$output"; then
        SKIPPED=$((SKIPPED+1))
    elif [[ $exit_code -eq 0 ]]; then
        PASSED=$((PASSED+1))
    else
    elif [[ $exit_code -eq 0 ]]; then
      PASSED=$((PASSED+1))
    else
      FAILED=1
      FAIL_LIST+=("$base")
    fi
  done
fi
    output="$(DOTFILES_ROOT="$REPO_ROOT" bash "$test_script" 2>&1 || true)"
    exit_code=$?
          set +e
          output="$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT" 2>&1)"
          exit_code=$?
          set -e
          echo "$output"
          echo "  - exit code: $exit_code"
          if grep -Eq '^[[:space:]]*SKIP:' <<<"$output"; then
              SKIPPED=$((SKIPPED+1))
          elif [[ $exit_code -eq 0 ]]; then
              PASSED=$((PASSED+1))
          else
              FAILED=1
              FAIL_LIST+=("$(basename "$test_script")")
          fi
              FAIL_LIST+=("$(basename "$test_script")")
          fi
if compgen -G "$SCRIPT_DIR/*.ps1" > /dev/null; then
  for test_script in "$SCRIPT_DIR"/*.ps1; do
      if command -v pwsh >/dev/null 2>&1; then
          echo
          echo "▶️ Running $(basename "$test_script")..."
          TOTAL=$((TOTAL+1))
          output="$(pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT" 2>&1 || true)"
          exit_code=$?
          echo "$output"
          echo "  - exit code: $exit_code"
          if grep -Eq '^[[:space:]]*SKIP:' <<<"$output"; then
              SKIPPED=$((SKIPPED+1))
          elif [[ $exit_code -eq 0 ]]; then
              PASSED=$((PASSED+1))
          else
              FAILED=1
              FAIL_LIST+=("$(basename "$test_script")")
          fi
      else
          echo "⚠️ Skipping $(basename "$test_script") (pwsh not available)"
      fi
  done
fi

echo
echo "📊 Summary: $PASSED / $TOTAL passed, $SKIPPED skipped"
if [[ $FAILED -eq 0 ]]; then
    echo "✅ Test suite successful"
    exit 0
else
    echo "❌ Some tests failed: ${FAIL_LIST[*]}"
    exit 1
fi
