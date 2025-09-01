# Run All Tests Script Design

## Overview

This document describes the design for `test/run-all-tests.sh`, which will orchestrate running all tests together with improved reporting.

## Requirements

1. Execute all test scripts in the test directory
2. Provide clear output showing which tests are running
3. Handle both shell and PowerShell tests
4. Provide a summary of results
5. Return appropriate exit codes
6. Handle missing dependencies gracefully

## Implementation

### Script Structure

```bash
#!/usr/bin/env bash
# test/run-all-tests.sh - Run all tests

set -euo pipefail

# Determine script and repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Initialize flags
FAILED=0
```

### Test Execution Logic

The script will iterate through all test scripts and execute them:

```bash
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
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        # Execute test and capture result
        if DOTFILES_ROOT="$REPO_ROOT" bash "$test_script"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo "✅ $(basename "$test_script") passed"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo "❌ $(basename "$test_script") failed"
            FAILED=1
        fi
    fi
done
```

### PowerShell Test Execution

```bash
# Run PowerShell tests if pwsh is available
for test_script in "$SCRIPT_DIR"/*.ps1; do
    if command -v pwsh >/dev/null 2>&1; then
        echo
        echo "▶️ Running $(basename "$test_script")..."
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        # Execute PowerShell test and capture result
        if pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo "✅ $(basename "$test_script") passed"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo "❌ $(basename "$test_script") failed"
            FAILED=1
        fi
    else
        echo "⚠️ Skipping $(basename "$test_script") (pwsh not available)"
    fi
done
```

### Summary and Exit Handling

```bash
# Print final summary
echo
echo "📊 Test Execution Summary"
echo "========================"
echo "Total test suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [[ $FAILED -eq 0 ]]; then
    echo
    echo "🎉 All test suites passed!"
    exit 0
else
    echo
    echo "❌ Some test suites failed."
    exit 1
fi
```

## Features

### 1. Comprehensive Test Execution

The script will execute all test files in the test directory:
- `test-env.sh`
- `test-environment-loading.sh`
- `test-vscode-integration.sh`
- `test-environment.sh` (new)
- `test-env.ps1` (PowerShell)

### 2. Clear Progress Indication

Each test will be clearly marked as it runs:
- Emoji indicators for visual clarity
- Clear naming of test files
- Success/failure indication for each test

### 3. Graceful Error Handling

- PowerShell tests are skipped if pwsh is not available
- Individual test failures don't stop the entire suite
- Clear error messages for failed tests

### 4. Detailed Summary

At the end of execution, a comprehensive summary will be provided:
- Total number of test suites executed
- Number of suites passed
- Number of suites failed
- Overall success/failure indication

## Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed

## Integration with Existing Scripts

The script will work with the existing `scripts/run-tests.sh` but provide enhanced functionality:
- Better output formatting
- More detailed reporting
- Consistent execution environment
