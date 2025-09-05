#!/usr/bin/env bash
# test/test-path-config.sh - Test PATH configuration in templates

set +euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_projects_path_included_once() {
    echo "🧪 Testing Projects folder included in PATH once (no duplicates)"
    ((TESTS_RUN++))

    # Check if projects_path.tmpl is included in both shell configs
    local zshrc_includes_projects
    local bashrc_includes_projects

    zshrc_includes_projects=$(grep -c "projects_path.tmpl" "$PWD/dot_zshrc.tmpl")
    bashrc_includes_projects=$(grep -c "projects_path.tmpl" "$PWD/dot_bashrc.tmpl")

    if [[ $zshrc_includes_projects -eq 1 && $bashrc_includes_projects -eq 1 ]]; then
        echo "✅ Projects path template included exactly once in both zshrc and bashrc"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Projects path template inclusion count mismatch"
        echo "   zshrc: $zshrc_includes_projects, bashrc: $bashrc_includes_projects"
        FAILED_TESTS+=("Projects path template inclusion count mismatch")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_platform_specific_path_entries() {
    echo "🧪 Testing platform-specific PATH entries"
    ((TESTS_RUN++))

    # Source platform detection to understand current platform
    source "$PWD/lib/platform-detection.sh" >/dev/null 2>&1
    detect_platform --force

    # Check if platform-specific templates exist (this will fail in Red phase)
    local platform_issues=()

    # For WSL, check if WSL-specific PATH template exists
    if [[ "$DOTFILES_PLATFORM" == "wsl" ]]; then
        if [[ ! -f "$PWD/templates/partials/wsl_path.tmpl" ]]; then
            platform_issues+=("Missing WSL-specific PATH template")
        fi
    fi

    # For Windows, check if Windows-specific PATH template exists
    if [[ "$DOTFILES_PLATFORM" == "windows" ]]; then
        if [[ ! -f "$PWD/templates/partials/windows_path.tmpl" ]]; then
            platform_issues+=("Missing Windows-specific PATH template")
        fi
    fi

    # For macOS, check if macOS-specific PATH template exists
    if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
        if [[ ! -f "$PWD/templates/partials/macos_path.tmpl" ]]; then
            platform_issues+=("Missing macOS-specific PATH template")
        fi
    fi

    if [[ ${#platform_issues[@]} -eq 0 ]]; then
        echo "✅ Platform-specific PATH templates exist for $DOTFILES_PLATFORM"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Platform-specific PATH issues: ${platform_issues[*]}"
        FAILED_TESTS+=("Platform PATH issues: ${platform_issues[*]}")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_path_idempotence() {
    echo "🧪 Testing PATH idempotence (re-sourcing doesn't duplicate)"
    ((TESTS_RUN++))

    # Create a test environment to simulate shell sourcing
    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Extract the actual shell code from projects path template (remove Go template syntax)
    local projects_path_content
    projects_path_content=$(cat "$PWD/templates/partials/projects_path.tmpl" | sed 's/{{.*}}//g' | grep -v '^#' | sed '/^$/d')

    # Create test files
    cat > "$temp_dir/test_script.sh" <<EOF
#!/usr/bin/env bash
# Test script to simulate shell sourcing
export PATH="/usr/bin:/bin"

# First source
$projects_path_content

# Capture first PATH
first_path="\$PATH"

# Second source (simulate re-sourcing)
$projects_path_content

# Capture second PATH
second_path="\$PATH"

echo "first_path=\$first_path"
echo "second_path=\$second_path"

# Check if paths are equal (no duplication)
if [[ "\$first_path" == "\$second_path" ]]; then
    exit 0
else
    exit 1
fi
EOF

    chmod +x "$temp_dir/test_script.sh"

    # Run the test
    if "$temp_dir/test_script.sh"; then
        echo "✅ PATH remains stable after re-sourcing (no duplication)"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ PATH duplication detected after re-sourcing"
        FAILED_TESTS+=("PATH duplication on re-sourcing")
        ((TESTS_FAILED++))
        return 1
    fi
}

main() {
    echo "🔬 Testing PATH Configuration in Templates"
    echo "========================================"

    # Run all tests
    test_projects_path_included_once
    test_platform_specific_path_entries
    test_path_idempotence

    test_summary
    exit $?
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
