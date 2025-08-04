#!/usr/bin/env bash
# test/run-all-tests.sh - Run all tests

set -euo pipefail

# Determine script and repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Initialize flags
FAILED=0

echo -e "${BLUE}🔬 Running all dotfiles tests...${NC}"
echo "==============================="

# Run shell tests
for test_script in "$SCRIPT_DIR"/*.sh; do
    # Skip this script and framework
    if [[ "$(basename "$test_script")" == "run-all-tests.sh" ]] || \
       [[ "$(basename "$test_script")" == "framework.sh" ]]; then
        continue
    fi

    if [[ -x "$test_script" ]]; then
        echo
        echo -e "${BLUE}▶️ Running $(basename "$test_script")...${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        # Execute test and capture result
        if DOTFILES_ROOT="$REPO_ROOT" bash "$test_script"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo -e "${GREEN}✅ $(basename "$test_script") passed${NC}"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo -e "${RED}❌ $(basename "$test_script") failed${NC}"
            FAILED=1
        fi
    fi
done

# Run PowerShell tests if pwsh is available
for test_script in "$SCRIPT_DIR"/*.ps1; do
    if command -v pwsh >/dev/null 2>&1; then
        echo
        echo -e "${BLUE}▶️ Running $(basename "$test_script")...${NC}"
        TOTAL_TESTS=$((TOTAL_TESTS + 1))

        # Execute PowerShell test and capture result
        if pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT"; then
            PASSED_TESTS=$((PASSED_TESTS + 1))
            echo -e "${GREEN}✅ $(basename "$test_script") passed${NC}"
        else
            FAILED_TESTS=$((FAILED_TESTS + 1))
            echo -e "${RED}❌ $(basename "$test_script") failed${NC}"
            FAILED=1
        fi
    else
        echo -e "${YELLOW}⚠️ Skipping $(basename "$test_script") (pwsh not available)${NC}"
    fi
done

# Print final summary
echo
echo -e "${BLUE}📊 Test Execution Summary${NC}"
echo "========================"
echo "Total test suites: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"

if [[ $FAILED -eq 0 ]]; then
    echo
    echo -e "${GREEN}🎉 All test suites passed!${NC}"
    exit 0
else
    echo
    echo -e "${RED}❌ Some test suites failed.${NC}"
    exit 1
fi
