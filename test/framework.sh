#!/usr/bin/env bash
# test/framework.sh - Comprehensive test framework for dotfiles

set -euo pipefail

# Test framework variables
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -a FAILED_TESTS=()

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Basic assertion function that evaluates a command and compares its output to an expected value
test_assert() {
    local description="$1"
    local command="$2"
    local expected="$3"

    ((TESTS_RUN++))

    local actual
    actual="$(eval "$command" 2>&1)"
    local exit_code=$?

    if [[ "$actual" == "$expected" && $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   ${YELLOW}Expected:${NC} $expected"
        echo -e "   ${YELLOW}Actual:${NC} $actual"
        echo -e "   ${YELLOW}Exit code:${NC} $exit_code"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assertion for equality comparison
test_assert_equal() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    test_assert "$description" "echo '$actual'" "$expected"
}

# Assertion for inequality comparison
test_assert_not_equal() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TESTS_RUN++))

    if [[ "$actual" != "$expected" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   ${YELLOW}Expected:${NC} not '$expected'"
        echo -e "   ${YELLOW}Actual:${NC} '$actual'"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assertion for substring containment
test_assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   ${YELLOW}Expected to contain:${NC} $needle"
        echo -e "   ${YELLOW}Actual:${NC} $haystack"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assertion for regex pattern matching
test_assert_matches() {
    local description="$1"
    local text="$2"
    local pattern="$3"

    ((TESTS_RUN++))

    if [[ "$text" =~ $pattern ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        echo -e "   ${YELLOW}Expected to match pattern:${NC} $pattern"
        echo -e "   ${YELLOW}Actual:${NC} $text"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to display test results summary
test_summary() {
    echo
    echo -e "${BLUE}📊 Test Results Summary${NC}"
    echo "======================"
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo
        echo -e "${RED}Failed tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}-${NC} $test"
        done
    fi

    echo
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed.${NC}"
        return 1
    fi
}
