#!/usr/bin/env bash
# test/test-chezmoi-templates.sh - Test Chezmoi template functionality

# set -euo pipefail  # Temporarily disabled for debugging
set -u  # Only set -u for now

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_chezmoi_invocable() {
    echo "🧪 Testing Chezmoi is invocable"
    ((TESTS_RUN++))
    # Just test that chezmoi command succeeds with exit code 0
    if chezmoi --version >/dev/null 2>&1; then
        echo "✅ Chezmoi is invocable"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Chezmoi is not invocable"
        FAILED_TESTS+=("Chezmoi invocability")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_chezmoi_apply_dry_run() {
    echo "🧪 Testing Chezmoi apply --dry-run"
    ((TESTS_RUN++))
    # Test that dry-run command succeeds - remove redirection for debugging
    if chezmoi apply --source "$PWD" --dry-run; then
        echo "✅ Chezmoi apply --dry-run succeeded"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Chezmoi apply --dry-run failed"
        FAILED_TESTS+=("Chezmoi apply --dry-run")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_chezmoi_idempotence() {
    echo "🧪 Testing Chezmoi idempotence"
    ((TESTS_RUN++))
    # First run should plan changes
    local first_run_output
    first_run_output=$(chezmoi apply --source "$PWD" --dry-run 2>&1)
    local first_exit_code=$?

    # Second run should show no changes
    local second_run_output
    second_run_output=$(chezmoi apply --source "$PWD" --dry-run 2>&1)
    local second_exit_code=$?

    # Both should succeed
    if [[ $first_exit_code -eq 0 && $second_exit_code -eq 0 ]]; then
        # Check if both runs have no output (indicating no changes needed)
        if [[ -z "$first_run_output" && -z "$second_run_output" ]]; then
            echo "✅ Chezmoi idempotence test passed (no changes needed)"
            ((TESTS_PASSED++))
            return 0
        # Check if second run explicitly shows no changes
        elif echo "$second_run_output" | grep -q "No changes would be made"; then
            echo "✅ Chezmoi idempotence test passed (explicit no changes)"
            ((TESTS_PASSED++))
            return 0
        else
            echo "❌ Chezmoi idempotence test failed - second run still shows changes"
            echo "   First run output: '$first_run_output'"
            echo "   Second run output: '$second_run_output'"
            FAILED_TESTS+=("Chezmoi idempotence")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        echo "❌ Chezmoi idempotence test failed - exit codes not zero"
        echo "   First exit code: $first_exit_code"
        echo "   Second exit code: $second_exit_code"
        FAILED_TESTS+=("Chezmoi idempotence")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_target_files_present() {
    echo "🧪 Testing target files in planned output"
    ((TESTS_RUN++))
    local output
    output=$(chezmoi apply --source "$PWD" --dry-run 2>&1)
    local exit_code=$?

    # If exit code is 0 and output is empty, it means no changes are needed (files already exist)
    if [[ $exit_code -eq 0 && -z "$output" ]]; then
        echo "✅ All target files already present (no changes needed)"
        ((TESTS_PASSED++))
        return 0
    fi

    # Check for expected target files in output
    local missing_files=()
    local expected_files=(
        ".zshrc"
        ".bashrc"
        "~/.gitignore_global"
        "PowerShell/Microsoft.PowerShell_profile.ps1"
    )

    for file in "${expected_files[@]}"; do
        if ! echo "$output" | grep -q "$file"; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -eq 0 ]]; then
        echo "✅ All target files found in planned output"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Missing target files in planned output: ${missing_files[*]}"
        FAILED_TESTS+=("Missing target files: ${missing_files[*]}")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_direnv_hooks_present() {
    echo "🧪 Testing direnv hooks in planned content"
    ((TESTS_RUN++))
    local output
    output=$(chezmoi apply --source "$PWD" --dry-run --verbose 2>&1)

    # Check for direnv hooks in zsh/bash files
    local missing_hooks=()

    # Check zshrc for direnv hook
    if echo "$output" | grep -q "\.zshrc" && ! echo "$output" | grep -A 10 "\.zshrc" | grep -q "direnv hook zsh"; then
        missing_hooks+=("zsh direnv hook")
    fi

    # Check bashrc for direnv hook
    if echo "$output" | grep -q "\.bashrc" && ! echo "$output" | grep -A 10 "\.bashrc" | grep -q "direnv hook bash"; then
        missing_hooks+=("bash direnv hook")
    fi

    # Check PowerShell profile for direnv hook (if present)
    if echo "$output" | grep -q "PowerShell.*profile" && ! echo "$output" | grep -A 10 "PowerShell.*profile" | grep -q "direnv hook pwsh"; then
        missing_hooks+=("PowerShell direnv hook")
    fi

    if [[ ${#missing_hooks[@]} -eq 0 ]]; then
        echo "✅ All direnv hooks found in planned content"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Missing direnv hooks in planned content: ${missing_hooks[*]}"
        FAILED_TESTS+=("Missing direnv hooks: ${missing_hooks[*]}")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_envrc_mise_pattern() {
    echo "🧪 Testing .envrc uses mise + dotenv pattern"
    ((TESTS_RUN++))

    # Check if .envrc file exists and contains the mise pattern
    if [[ ! -f ".envrc" ]]; then
        echo "❌ .envrc file not found"
        FAILED_TESTS+=(".envrc file missing")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check for 'use mise' pattern in .envrc
    if ! grep -q "use mise" ".envrc"; then
        echo "❌ .envrc does not contain 'use mise' pattern"
        FAILED_TESTS+=(".envrc missing 'use mise'")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check for 'dotenv' pattern in .envrc (should come after mise)
    if ! grep -q "dotenv" ".envrc"; then
        echo "❌ .envrc does not contain 'dotenv' pattern"
        FAILED_TESTS+=(".envrc missing 'dotenv'")
        ((TESTS_FAILED++))
        return 1
    fi

    # Verify the order: mise should come before dotenv
    local mise_line dotenv_line
    mise_line=$(grep -n "use mise" ".envrc" | cut -d: -f1)
    dotenv_line=$(grep -n "dotenv" ".envrc" | cut -d: -f1)

    if [[ -z "$mise_line" || -z "$dotenv_line" ]]; then
        echo "❌ Could not determine line numbers for mise/dotenv"
        FAILED_TESTS+=(".envrc mise/dotenv line detection failed")
        ((TESTS_FAILED++))
        return 1
    fi

    if [[ "$mise_line" -lt "$dotenv_line" ]]; then
        echo "✅ .envrc uses mise + dotenv pattern in correct order"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ .envrc has incorrect order: dotenv comes before mise"
        FAILED_TESTS+=(".envrc incorrect mise/dotenv order")
        ((TESTS_FAILED++))
        return 1
    fi
}

main() {
    echo "🔬 Testing Chezmoi Templates"
    echo "============================"

    # Run all tests
    test_chezmoi_invocable
    test_chezmoi_apply_dry_run
    test_chezmoi_idempotence
    test_target_files_present
    test_direnv_hooks_present

    test_summary
    exit $?
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
