#!/usr/bin/env bash
# test/test-mise-adoption.sh - Test Mise adoption and Volta deprecation

set -euo pipefail

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_no_volta_path_injection() {
    echo "🧪 Testing no Volta PATH injection in new shells"
    ((TESTS_RUN++))

    local files_to_check=(
        ".shell_common.sh"
        "lib/env-loader.sh"
        "zsh/path.zsh"
        ".envrc"
    )

    local found_injection=false

    for file in "${files_to_check[@]}"; do
        if [[ -f "$file" ]]; then
            # Check for explicit Volta PATH injection patterns
            # Use explicit exit code checking to avoid set -e issues
            local grep_result=0
            grep -q "export PATH.*VOLTA_HOME" "$file" || grep_result=$?
            if [[ $grep_result -eq 0 ]]; then
                echo "❌ Volta PATH injection found in $file (export PATH pattern)"
                FAILED_TESTS+=("Volta PATH injection in $file")
                ((TESTS_FAILED++))
                found_injection=true
                continue
            fi

            grep_result=0
            grep -q "VOLTA_HOME.*PATH" "$file" || grep_result=$?
            if [[ $grep_result -eq 0 ]]; then
                echo "❌ Volta PATH injection found in $file (VOLTA_HOME PATH pattern)"
                FAILED_TESTS+=("Volta PATH injection in $file")
                ((TESTS_FAILED++))
                found_injection=true
                continue
            fi

            grep_result=0
            grep -q "PATH.*VOLTA_HOME" "$file" || grep_result=$?
            if [[ $grep_result -eq 0 ]]; then
                echo "❌ Volta PATH injection found in $file (PATH VOLTA_HOME pattern)"
                FAILED_TESTS+=("Volta PATH injection in $file")
                ((TESTS_FAILED++))
                found_injection=true
                continue
            fi
        fi
    done

    if [[ "$found_injection" == "true" ]]; then
        return 1
    fi

    echo "✅ No Volta PATH injection found in any shell configuration files"
    ((TESTS_PASSED++))
    return 0
}

test_mise_config_present() {
    echo "🧪 Testing mise config file presence"
    ((TESTS_RUN++))

    # Check if dot_mise.toml template exists
    if [[ ! -f "dot_mise.toml" ]]; then
        echo "❌ dot_mise.toml template not found"
        FAILED_TESTS+=("dot_mise.toml template missing")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check if chezmoi manages the mise config file
    if chezmoi managed --source "$PWD" | grep -q "dot_mise\.toml"; then
        echo "✅ mise config file is managed by chezmoi"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ mise config file not managed by chezmoi"
        FAILED_TESTS+=("mise config not managed by chezmoi")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_mise_dry_run() {
    echo "🧪 Testing mise install --dry-run"
    ((TESTS_RUN++))

    # Require chezmoi (to materialize .mise.toml) and mise
    if ! command -v chezmoi >/dev/null 2>&1; then
        echo "⚠️  chezmoi not installed, skipping dry-run test"
        ((TESTS_SKIPPED++))
        return 0
    fi
    if ! command -v mise >/dev/null 2>&1; then
        echo "⚠️  mise not installed, skipping dry-run test"
        ((TESTS_SKIPPED++))
        return 0
    fi

    local tmpdest
    tmpdest="$(mktemp -d)"
    trap 'rm -rf "$tmpdest"' RETURN
    if ! chezmoi apply --source "$PWD" --destination "$tmpdest" >/dev/null 2>&1; then
        echo "❌ failed to render .mise.toml to temp destination"
        FAILED_TESTS+=("mise dry-run - render failed")
        ((TESTS_FAILED++))
        return 1
    fi

    MISE_CONFIG_FILE="$tmpdest/.mise.toml" MISE_DATA_DIR="$tmpdest/.local/share/mise" \
      mise install --dry-run >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
        echo "✅ mise install --dry-run succeeded"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ mise install --dry-run failed"
        FAILED_TESTS+=("mise install --dry-run failed")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_mise_idempotence() {
    echo "🧪 Testing mise install idempotence"
    ((TESTS_RUN++))

    # Skip if not explicitly allowed
    if [[ "${MISE_TEST_ALLOW_INSTALL:-0}" != "1" ]]; then
        echo "⚠️  skipping idempotence test (set MISE_TEST_ALLOW_INSTALL=1 to enable)"
        ((TESTS_SKIPPED++))
        return 0
    fi

    # Require chezmoi and mise
    if ! command -v chezmoi >/dev/null 2>&1; then
        echo "⚠️  chezmoi not installed, skipping idempotence test"
        ((TESTS_SKIPPED++))
        return 0
    fi
    if ! command -v mise >/dev/null 2>&1; then
        echo "⚠️  mise not installed, skipping idempotence test"
        ((TESTS_SKIPPED++))
        return 0
    fi

    # Render config to a temp destination
    local tmpdest
    tmpdest="$(mktemp -d)"
    trap 'rm -rf "$tmpdest"' RETURN
    chezmoi apply --source "$PWD" --destination "$tmpdest" >/dev/null 2>&1 || {
        echo "❌ failed to render .mise.toml to temp destination"
        FAILED_TESTS+=("mise idempotence - render failed")
        ((TESTS_FAILED++))
        return 1
    }

    # First run - capture output
    local first_output
    first_output=$(MISE_CONFIG_FILE="$tmpdest/.mise.toml" MISE_DATA_DIR="$tmpdest/.local/share/mise" mise install 2>&1)
    local first_exit_code=$?

    # Second run - should be no-op
    local second_output
    second_output=$(MISE_CONFIG_FILE="$tmpdest/.mise.toml" MISE_DATA_DIR="$tmpdest/.local/share/mise" mise install 2>&1)
    local second_exit_code=$?

    if [[ $first_exit_code -eq 0 && $second_exit_code -eq 0 ]]; then
        # Check if second run shows no changes or is empty (excluding trust warnings)
        if [[ -z "$second_output" ]] || echo "$second_output" | grep -q "already installed\|no changes\|up to date\|all tools are installed"; then
            echo "✅ mise install idempotence test passed"
            ((TESTS_PASSED++))
            return 0
        else
            echo "❌ mise install idempotence test failed - second run still shows output"
            echo "   First output: '$first_output'"
            echo "   Second output: '$second_output'"
            FAILED_TESTS+=("mise install not idempotent")
            ((TESTS_FAILED++))
            return 1
        fi
    else
        echo "❌ mise install idempotence test failed - exit codes not zero"
        echo "   First exit code: $first_exit_code"
        echo "   Second exit code: $second_exit_code"
        FAILED_TESTS+=("mise install exit codes not zero")
        ((TESTS_FAILED++))
        return 1
    fi
}

main() {
    echo "🔬 Testing Mise Adoption and Volta Deprecation"
    echo "=============================================="

    # Run all tests
    test_no_volta_path_injection
    test_mise_config_present
    test_mise_dry_run
    test_mise_idempotence

    test_summary
    exit $?
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
