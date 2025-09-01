# Test Framework Implementation Details

## test/framework.sh

This file will contain the core test framework implementation with assertion functions and result tracking.

### Core Variables

```bash
# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -a FAILED_TESTS=()
```

### Core Functions

#### test_assert

Basic assertion function that evaluates a command and compares its output to an expected value.

```bash
test_assert() {
    local description="$1"
    local command="$2"
    local expected="$3"

    ((TESTS_RUN++))

    local actual
    actual="$(eval "$command" 2>&1)"
    local exit_code=$?

    if [[ "$actual" == "$expected" && $exit_code -eq 0 ]]; then
        echo "✅ $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ $description"
        echo "   Expected: $expected"
        echo "   Actual: $actual"
        echo "   Exit code: $exit_code"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}
```

#### test_assert_equal

Assertion for equality comparison.

```bash
test_assert_equal() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    test_assert "$description" "echo '$actual'" "$expected"
}
```

#### test_assert_not_equal

Assertion for inequality comparison.

```bash
test_assert_not_equal() {
    local description="$1"
    local actual="$2"
    local expected="$3"

    ((TESTS_RUN++))

    if [[ "$actual" != "$expected" ]]; then
        echo "✅ $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ $description"
        echo "   Expected: not '$expected'"
        echo "   Actual: '$actual'"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}
```

#### test_assert_contains

Assertion for substring containment.

```bash
test_assert_contains() {
    local description="$1"
    local haystack="$2"
    local needle="$3"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✅ $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ $description"
        echo "   Expected to contain: $needle"
        echo "   Actual: $haystack"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}
```

#### test_assert_matches

Assertion for regex pattern matching.

```bash
test_assert_matches() {
    local description="$1"
    local text="$2"
    local pattern="$3"

    ((TESTS_RUN++))

    if [[ "$text" =~ $pattern ]]; then
        echo "✅ $description"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ $description"
        echo "   Expected to match pattern: $pattern"
        echo "   Actual: $text"
        FAILED_TESTS+=("$description")
        ((TESTS_FAILED++))
        return 1
    fi
}
```

#### test_summary

Function to display test results summary.

```bash
test_summary() {
    echo
    echo "📊 Test Results Summary"
    echo "======================"
    echo "Tests run: $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi

    echo
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 All tests passed!"
        return 0
    else
        echo "❌ Some tests failed."
        return 1
    fi
}
```

## test/test-environment.sh

This file will contain environment loading tests using the framework.

### Test Structure

```bash
#!/usr/bin/env bash
# test/test-environment.sh - Environment loading tests

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_environment_loading() {
    echo "🧪 Testing Environment Loading"
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
```

## test/run-all-tests.sh

This file will orchestrate running all tests together.

### Implementation

```bash
#!/usr/bin/env bash
# test/run-all-tests.sh - Run all tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔬 Running all dotfiles tests..."
echo "==============================="

FAILED=0

# Run shell tests
for test_script in "$SCRIPT_DIR"/*.sh; do
    # Skip this script and framework
    if [[ "$(basename "$test_script")" == "run-all-tests.sh" ]] || \
       [[ "$(basename "$test_script")" == "framework.sh" ]]; then
        continue
    fi

    if [[ -x "$test_script" ]]; then
        echo
        echo "▶️ Running $(basename "$test_script")..."
        DOTFILES_ROOT="$REPO_ROOT" bash "$test_script" || FAILED=1
    fi
done

# Run PowerShell tests if pwsh is available
for test_script in "$TEST_DIR"/*.ps1; do
    if command -v pwsh >/dev/null 2>&1; then
        echo
        echo "▶️ Running $(basename "$test_script")..."
        pwsh -NoProfile -ExecutionPolicy Bypass -File "$test_script" -DotfilesRoot "$REPO_ROOT" || FAILED=1
    else
        echo "⚠️ Skipping $(basename "$test_script") (pwsh not available)"
    fi
done

echo
if [[ $FAILED -eq 0 ]]; then
    echo "✅ All tests passed"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
```

## Integration with Existing Tests

### Updating test/test-environment-loading.sh

The existing test file will be updated to use the new framework:

```bash
#!/usr/bin/env bash
# test/test-environment-loading.sh - Test environment loading functionality

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# ... existing test functions, but using test_assert instead of custom assert

# In the main execution block:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Ensure we're in the dotfiles directory and environment is loaded
    cd "$(dirname "$0")/.."
    source .shell_common.sh

    test_environment_loading
    test_summary  # Use the framework's summary function
    exit $?  # Use the framework's exit code
fi
```

### Benefits of Integration

1. **Consistent Output**: All tests will have the same output format
2. **Centralized Logic**: Assertion logic is in one place
3. **Better Reporting**: Detailed failure information for all tests
4. **Extensibility**: Easy to add new assertion types
