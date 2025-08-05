# Integration with Existing Tests

## Overview

This document describes how the new testing infrastructure will integrate with the existing test files while maintaining backward compatibility.

## Existing Test Files

1. `test/test-env.sh` - Unit tests for Bash/Zsh environment loader
2. `test/test-env.ps1` - Unit tests for PowerShell environment loader
3. `test/test-environment-loading.sh` - Environment loading functionality tests
4. `test/test-vscode-integration.sh` - VS Code settings integration tests

## Integration Strategy

### 1. Backward Compatibility

All existing tests will continue to work without modification:
- They will maintain their current interfaces
- They will continue to be executable individually
- They will continue to be compatible with `scripts/run-tests.sh`

### 2. Selective Enhancement

Some tests will be enhanced to use the new framework:
- `test/test-environment-loading.sh` will be updated to use the new assertion functions
- The test structure will remain the same but with improved reporting

### 3. Unified Execution

All tests can be executed together via the new `test/run-all-tests.sh` script.

## Integration Details

### test/test-env.sh

This file will remain unchanged as it already has a well-defined structure and doesn't need the new framework features.

Current structure:
```bash
# Uses custom assertion logic
if [[ "$FOO" != "bar" ]]; then
  echo "Test failed: FOO expected 'bar' but got '${FOO:-}'" >&2
  exit 1
fi
```

No changes needed as it's working well and doesn't require the new framework.

### test/test-env.ps1

This PowerShell test will remain unchanged as it's specific to PowerShell and doesn't need the Bash framework.

### test/test-environment-loading.sh

This file will be updated to use the new framework:

Before:
```bash
test_assert() {
    local description="$1"
    local command="$2"
    local expected="$3"
    # Custom implementation
}
```

After:
```bash
# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# Use framework's test_assert function
```

Benefits:
- Consistent output formatting
- Better failure reporting
- Centralized assertion logic

### test/test-vscode-integration.sh

This file will remain largely unchanged but will be updated to use the framework's summary function:

```bash
# Add at the top
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# In the main function, replace custom summary with:
test_summary  # Use the framework's summary function
```

## Migration Plan

### Phase 1: Framework Implementation

1. Create `test/framework.sh` with all assertion functions
2. Create `test/test-environment.sh` with new environment tests
3. Create `test/run-all-tests.sh` for unified execution

### Phase 2: Selective Integration

1. Update `test/test-environment-loading.sh` to use the new framework
2. Update `test/test-vscode-integration.sh` to use the framework summary
3. Verify all existing tests still pass

### Phase 3: Documentation and Testing

1. Document the integration
2. Test all execution paths:
   - Individual test execution
   - Unified test execution
   - Backward compatibility with `scripts/run-tests.sh`

## Benefits of Integration

### 1. Consistent User Experience

All tests will have the same output format and behavior:
- Same emoji indicators
- Same failure reporting
- Same exit code handling

### 2. Reduced Code Duplication

Assertion logic will be centralized in the framework:
- Easier maintenance
- Consistent behavior
- Single point for improvements

### 3. Enhanced Reporting

Better failure information for tests using the framework:
- Expected vs actual values
- Exit codes
- Detailed error messages

### 4. Extensibility

Easy to add new assertion types:
- All tests benefit from new features
- No need to update individual test files

## Backward Compatibility Guarantees

### 1. Interface Preservation

- All existing test files will maintain their current execution interfaces
- No changes to command-line arguments or environment variable requirements
- All tests will continue to work with `scripts/run-tests.sh`

### 2. Execution Compatibility

- Individual test execution will work exactly as before
- Test output format will be improved but not broken
- Exit codes will remain consistent

### 3. Dependency Management

- No new required dependencies for existing tests
- Optional enhancement for tests that choose to use the framework
- Graceful degradation if framework is not available

## Testing the Integration

### 1. Compatibility Testing

- Verify all existing tests pass with no changes
- Verify `scripts/run-tests.sh` still works
- Verify individual test execution still works

### 2. Enhancement Testing

- Verify tests using the framework produce enhanced output
- Verify framework functions work correctly
- Verify unified test execution works

### 3. Regression Testing

- Verify no performance degradation
- Verify no new dependencies break existing functionality
- Verify all platforms still work (Linux, macOS, WSL)
