#!/usr/bin/env bash
# test/test-environment-loading.sh - Test environment loading functionality

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# test_environment_loading runs a suite of assertions to verify that key environment variables are correctly loaded and set within the dotfiles repository.
test_environment_loading() {
    echo "🧪 Testing Environment Loading System"
    echo "======================================"

    # Test DOTFILES_ROOT is set correctly
    # Expect DOTFILES_ROOT to equal repo root
    local expected_root
    expected_root="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
    test_assert "DOTFILES_ROOT is set to correct path" \
                'echo "$DOTFILES_ROOT"' \
                "$expected_root"

    # Test GEMINI_API_KEY is loaded
    # Allow missing GEMINI_API_KEY if no .env present; treat as pass when .env/.env.example absent
    local expect_secret="SET"
    if [[ ! -f "$(dirname "$BASH_SOURCE")/../.env" ]]; then
        expect_secret="UNSET"
    fi
    test_assert "GEMINI_API_KEY is loaded" \
                '[[ -n "$GEMINI_API_KEY" ]] && echo "SET" || echo "UNSET"' \
                "$expect_secret"

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
}

# Run tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure we're in the dotfiles directory and environment is loaded
    cd "$(dirname "$0")/.."
    source .shell_common.sh

    test_environment_loading
    test_summary
    exit $?
fi
