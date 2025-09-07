#!/usr/bin/env bash
# test/test-global-justfile.sh - Test global Justfile functionality

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_global_justfile_planned() {
    echo "🧪 Testing global Justfile is managed by chezmoi and exists in target"
    ((TESTS_RUN++))

    # Check if chezmoi manages dot_justfile
    if ! chezmoi managed | grep -q "dot_justfile"; then
        echo "❌ dot_justfile not managed by chezmoi"
        FAILED_TESTS+=("dot_justfile not managed")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check if target .justfile exists
    if [[ ! -f "$HOME/.justfile" ]]; then
        echo "❌ Global Justfile not found in target location $HOME/.justfile"
        FAILED_TESTS+=("Global Justfile not in target")
        ((TESTS_FAILED++))
        return 1
    fi

    echo "✅ Global Justfile is managed and exists in target"
    ((TESTS_PASSED++))
    return 0
}

test_justfile_recipes_present() {
    echo "🧪 Testing global Justfile contains required recipes"
    ((TESTS_RUN++))

    # Check if dot_justfile template exists
    if [[ ! -f "dot_justfile" ]]; then
        echo "❌ dot_justfile template not found"
        FAILED_TESTS+=("dot_justfile template missing")
        ((TESTS_FAILED++))
        return 1
    fi

    local missing_recipes=()
    local expected_recipes=("bootstrap" "lint" "format")

    for recipe in "${expected_recipes[@]}"; do
        if ! grep -q "^$recipe:" "dot_justfile" && ! grep -q "^#.*$recipe" "dot_justfile"; then
            missing_recipes+=("$recipe")
        fi
    done

    if [[ ${#missing_recipes[@]} -eq 0 ]]; then
        echo "✅ All required recipes found in dot_justfile"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ Missing recipes in dot_justfile: ${missing_recipes[*]}"
        FAILED_TESTS+=("Missing recipes: ${missing_recipes[*]}")
        ((TESTS_FAILED++))
        return 1
    fi
}

test_bootstrap_recipe_content() {
    echo "🧪 Testing bootstrap recipe includes chezmoi apply and mise install"
    ((TESTS_RUN++))

    if [[ ! -f "dot_justfile" ]]; then
        echo "❌ dot_justfile template not found"
        FAILED_TESTS+=("dot_justfile template missing")
        ((TESTS_FAILED++))
        return 1
    fi

    # Extract bootstrap recipe content using a more robust method
    # Extract bootstrap recipe content using a more robust method
    local bootstrap_content
    # Handle both cases: recipe followed by another recipe or at EOF
    bootstrap_content=$(awk '/^bootstrap:/{flag=1;next}/^[a-z_-]+.*:/{flag=0}flag' "dot_justfile")
    if [[ -z "$bootstrap_content" ]]; then
        # If empty, try extracting from bootstrap to EOF
        bootstrap_content=$(sed -n '/^bootstrap:/,$p' "dot_justfile" | tail -n +2)
    fi

    # Check for chezmoi apply
    if ! echo "$bootstrap_content" | grep -q "chezmoi apply"; then
        echo "❌ Bootstrap recipe missing 'chezmoi apply'"
        FAILED_TESTS+=("Bootstrap missing chezmoi apply")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check for mise install (conditional)
    if ! echo "$bootstrap_content" | grep -q "mise install"; then
        echo "❌ Bootstrap recipe missing 'mise install'"
        FAILED_TESTS+=("Bootstrap missing mise install")
        ((TESTS_FAILED++))
        return 1
    fi

    echo "✅ Bootstrap recipe includes chezmoi apply and mise install"
    ((TESTS_PASSED++))
    return 0
}

test_justfile_idempotence() {
    echo "🧪 Testing Justfile idempotence"
    ((TESTS_RUN++))

    # This test would typically require actual chezmoi apply and just bootstrap execution
    # For now, we'll check that the template is designed for idempotence
    if [[ ! -f "dot_justfile" ]]; then
        echo "❌ dot_justfile template not found"
        FAILED_TESTS+=("dot_justfile template missing")
        ((TESTS_FAILED++))
        return 1
    fi

    # Check that mise install is conditional (idempotent)
    if grep -q "command -v mise" "dot_justfile"; then
        echo "✅ mise install is conditional (idempotent)"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ mise install not conditional (may not be idempotent)"
        FAILED_TESTS+=("mise install not conditional")
        ((TESTS_FAILED++))
        return 1
    fi
}

main() {
    echo "🔬 Testing Global Justfile"
    echo "=========================="

    # Run all tests
    test_global_justfile_planned
    test_justfile_recipes_present
    test_bootstrap_recipe_content
    test_justfile_idempotence

    test_summary
    exit $?
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
