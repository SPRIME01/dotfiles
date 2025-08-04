#!/bin/bash

# Test script for VS Code settings integration
# This script verifies that the VS Code settings integration works correctly

# Source the test framework for summary functionality
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    log_info "Running: $test_name"

    if eval "$test_command"; then
        log_success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Test 1: Check if base settings file exists
test_base_settings() {
    [[ -f "$DOTFILES_DIR/.config/Code/User/settings.json" ]]
}

# Test 2: Check if platform-specific settings exist
test_platform_settings() {
    [[ -f "$DOTFILES_DIR/.config/Code/User/settings.linux.json" ]] && \
    [[ -f "$DOTFILES_DIR/.config/Code/User/settings.windows.json" ]] && \
    [[ -f "$DOTFILES_DIR/.config/Code/User/settings.darwin.json" ]] && \
    [[ -f "$DOTFILES_DIR/.config/Code/User/settings.wsl.json" ]]
}

# Test 3: Check if installation script exists and is executable
test_install_script() {
    [[ -f "$DOTFILES_DIR/install/vscode.sh" ]] && \
    [[ -x "$DOTFILES_DIR/install/vscode.sh" ]]
}

# Test 4: Validate JSON syntax of base settings
test_json_syntax_base() {
    if command -v jq &> /dev/null; then
        jq empty "$DOTFILES_DIR/.config/Code/User/settings.json" 2>/dev/null
    else
        log_warning "jq not available, skipping JSON validation"
        return 0
    fi
}

# Test 5: Validate JSON syntax of platform settings
test_json_syntax_platform() {
    if command -v jq &> /dev/null; then
        local result=0
        for platform in linux windows darwin wsl; do
            if ! jq empty "$DOTFILES_DIR/.config/Code/User/settings.$platform.json" 2>/dev/null; then
                log_error "Invalid JSON in settings.$platform.json"
                result=1
            fi
        done
        return $result
    else
        log_warning "jq not available, skipping JSON validation"
        return 0
    fi
}

# Test 6: Test context detection
test_context_detection() {
    local context
    context=$(bash -c "source '$DOTFILES_DIR/install/vscode.sh'; detect_context" 2>/dev/null)
    [[ "$context" != "unknown" && -n "$context" ]]
}

# Test 7: Test dry-run of installation (without actually installing)
test_dry_run() {
    # Create a temporary directory for testing
    local temp_dir
    temp_dir=$(mktemp -d)

    # Test the script without actually modifying system files
    export HOME="$temp_dir"
    mkdir -p "$temp_dir/.config/Code/User"

    # Source the installation script and test setup function
    if bash -c "
        source '$DOTFILES_DIR/install/vscode.sh'
        setup_settings_file '$temp_dir/.config/Code/User/settings.json' 'linux'
    " 2>/dev/null; then
        # Check if the file was created
        if [[ -f "$temp_dir/.config/Code/User/settings.json" ]]; then
            rm -rf "$temp_dir"
            return 0
        fi
    fi

    rm -rf "$temp_dir"
    return 1
}

# Test 8: Test JSON merging functionality
test_json_merging() {
    if command -v jq &> /dev/null; then
        local temp_dir
        temp_dir=$(mktemp -d)

        # Create test files
        echo '{"a": 1, "b": 2}' > "$temp_dir/base.json"
        echo '{"b": 3, "c": 4}' > "$temp_dir/override.json"

        # Test merging
        jq -s '.[0] * .[1]' "$temp_dir/base.json" "$temp_dir/override.json" > "$temp_dir/merged.json"

        # Check if merge worked correctly
        local result=0
        if ! jq -e '.a == 1 and .b == 3 and .c == 4' "$temp_dir/merged.json" &>/dev/null; then
            result=1
        fi

        rm -rf "$temp_dir"
        return $result
    else
        log_warning "jq not available, skipping JSON merge test"
        return 0
    fi
}

# Test 9: Check if bootstrap script includes VS Code setup
test_bootstrap_integration() {
    grep -q "vscode.sh" "$DOTFILES_DIR/bootstrap.sh"
}

# Test 10: Verify no Windows-specific paths in base settings
test_no_windows_paths() {
    if ! grep -q "C:\\\\" "$DOTFILES_DIR/.config/Code/User/settings.json" && \
       ! grep -q "AppData" "$DOTFILES_DIR/.config/Code/User/settings.json"; then
        return 0
    else
        return 1
    fi
}

# Main test runner
main() {
    log_info "Starting VS Code settings integration tests..."
    echo

    # Run all tests
    run_test "Base settings file exists" "test_base_settings"
    run_test "Platform-specific settings exist" "test_platform_settings"
    run_test "Installation script is executable" "test_install_script"
    run_test "Base settings JSON syntax is valid" "test_json_syntax_base"
    run_test "Platform settings JSON syntax is valid" "test_json_syntax_platform"
    run_test "Context detection works" "test_context_detection"
    run_test "Dry-run installation works" "test_dry_run"
    run_test "JSON merging functionality works" "test_json_merging"
    run_test "Bootstrap script includes VS Code setup" "test_bootstrap_integration"
    run_test "Base settings have no Windows-specific paths" "test_no_windows_paths"

    # Use the framework's summary function
    # Map our counters to the framework's variables
    TESTS_RUN=$TESTS_RUN
    TESTS_PASSED=$TESTS_PASSED
    TESTS_FAILED=$TESTS_FAILED

    test_summary
    exit $?
}

# Run main function
main "$@"
