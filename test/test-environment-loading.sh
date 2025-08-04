#!/usr/bin/env bash
# test/test-environment-loading.sh - Test environment loading functionality

set -e  # Exit on error but allow unset variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0

test_assert() {
    local description="$1"
    local command="$2"
    local expected="$3"
    
    ((TESTS_RUN++))
    
    echo -n "Testing: $description... "
    
    local actual
    actual=$(eval "$command" 2>/dev/null)
    local exit_code=$?
    
    if [[ "$actual" == "$expected" && $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo -e "  ${YELLOW}Expected:${NC} $expected"
        echo -e "  ${YELLOW}Actual:${NC} $actual"
        echo -e "  ${YELLOW}Exit code:${NC} $exit_code"
        return 1
    fi
}

test_environment_loading() {
    echo "🧪 Testing Environment Loading System"
    echo "======================================"
    
    # Test DOTFILES_ROOT is set correctly
    test_assert "DOTFILES_ROOT is set to correct path" \
                'echo "$DOTFILES_ROOT"' \
                '/home/sprime01/dotfiles'
    
    # Test GEMINI_API_KEY is loaded
    test_assert "GEMINI_API_KEY is loaded" \
                '[[ -n "$GEMINI_API_KEY" ]] && echo "SET" || echo "UNSET"' \
                'SET'
    
    # Test PROJECTS_ROOT has default value
    test_assert "PROJECTS_ROOT has default value" \
                'echo "$PROJECTS_ROOT"' \
                "$HOME/projects"
    
    # Test platform detection
    test_assert "Platform detection works" \
                '[[ -n "$DOTFILES_PLATFORM" ]] && echo "SET" || echo "UNSET"' \
                'SET'
    
    # Test shell detection
    test_assert "Shell detection works" \
                '[[ -n "$DOTFILES_SHELL" ]] && echo "SET" || echo "UNSET"' \
                'SET'
    
    echo
    echo "📊 Test Results: $TESTS_PASSED/$TESTS_RUN tests passed"
    
    if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        return 1
    fi
}

# Run tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure we're in the dotfiles directory and environment is loaded
    cd "$(dirname "$0")/.."
    source .shell_common.sh
    
    test_environment_loading
fi
