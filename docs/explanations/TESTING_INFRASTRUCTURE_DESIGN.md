# Testing Infrastructure Design

## Overview

This document outlines the design for a comprehensive testing infrastructure for the dotfiles project, as specified in Phase 3.2 of the DOTFILES_RESOLUTION_PLANS.md. The testing infrastructure will provide a unified framework for testing all aspects of the dotfiles configuration.

## File Structure

```
test/
├── framework.sh                 # Test framework with assertion functions and result tracking
├── test-environment.sh          # Environment loading tests
├── test-env.sh                  # Existing Bash/Zsh environment loader tests
├── test-env.ps1                 # Existing PowerShell environment loader tests
├── test-environment-loading.sh  # Existing environment loading tests
├── test-vscode-integration.sh   # Existing VS Code integration tests
└── run-all-tests.sh             # Test runner that executes all tests
```

## Test Framework (test/framework.sh)

The test framework will provide:

1. **Test Assertion Functions**:
   - `test_assert` - Basic assertion function
   - `test_assert_equal` - Equality assertion
   - `test_assert_not_equal` - Inequality assertion
   - `test_assert_contains` - Substring containment assertion
   - `test_assert_matches` - Regex pattern matching assertion

2. **Test Result Tracking**:
   - Track number of tests run
   - Track number of tests passed
   - Track number of tests failed
   - Maintain list of failed tests for detailed reporting

3. **Test Output Formatting**:
   - Color-coded output for pass/fail status
   - Detailed failure information
   - Summary statistics

## Environment Loading Tests (test/test-environment.sh)

This file will contain tests for:

1. **Basic Environment Loading**:
   - DOTFILES_ROOT is set correctly
   - GEMINI_API_KEY is loaded
   - PROJECTS_ROOT has default value

2. **Platform Detection**:
   - Platform detection works correctly
   - Shell detection works correctly

3. **Environment Variable Validation**:
   - Required environment variables are present
   - Environment variable values are correct

## Integration with Existing Tests

The new testing infrastructure will integrate with existing test files by:

1. **Using the Common Framework**:
   - Existing tests will be updated to use the new assertion functions
   - Consistent output formatting across all tests

2. **Unified Test Runner**:
   - All tests can be executed together via `run-all-tests.sh`
   - Individual tests can still be run separately

3. **Backward Compatibility**:
   - Existing test functionality will be preserved
   - No breaking changes to existing test interfaces

## Test Execution

### Running All Tests

```bash
# Run all tests
./test/run-all-tests.sh
```

### Running Individual Tests

```bash
# Run environment loading tests
./test/test-environment.sh

# Run existing environment tests
./test/test-environment-loading.sh

# Run VS Code integration tests
./test/test-vscode-integration.sh
```

## Implementation Plan

1. **Create test/framework.sh**:
   - Implement assertion functions
   - Implement result tracking
   - Implement output formatting

2. **Create test/test-environment.sh**:
   - Implement environment loading tests
   - Use the new framework functions

3. **Create test/run-all-tests.sh**:
   - Implement unified test runner
   - Provide summary statistics
   - Handle exit codes properly

4. **Update existing tests**:
   - Integrate with the new framework where appropriate
   - Maintain backward compatibility

## Benefits

1. **Consistency**: Unified testing approach across all test files
2. **Maintainability**: Centralized test framework reduces duplication
3. **Extensibility**: Easy to add new test types and assertion functions
4. **Reporting**: Improved test output with detailed failure information
5. **Integration**: Seamless integration with existing tests
