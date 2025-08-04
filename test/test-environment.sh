#!/usr/bin/env bash
# test/test-environment.sh - Environment loading tests

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_environment_loading() {
    echo -e "${BLUE}🧪 Testing Environment Loading${NC}"
    echo "=============================="

    # Test DOTFILES_ROOT is set correctly
    test_assert "DOTFILES_ROOT is set" \
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
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure we're in the dotfiles directory and environment is loaded
    cd "$(dirname "$0")/.."
    source .shell_common.sh

    test_environment_loading
    test_summary
    exit $?
fi
