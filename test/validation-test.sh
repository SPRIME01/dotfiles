#!/usr/bin/env bash
# Test for validation functions
# SECURITY: This file uses only test/dummy values - never real API keys!

set -euo pipefail

echo "Testing validation functions..."

# Source the validation functions
source ./lib/validation.sh

echo "Testing validate_env_file:"
validate_env_file "./.env" false

echo "Testing validate_env_pair with test data:"
# IMPORTANT: Always use dummy/test values in test files
TEST_API_KEY="test_api_key_for_validation_purposes_only"
validate_env_pair "GEMINI_API_KEY" "\"$TEST_API_KEY\""

# Test with different formats
echo "Testing different quote formats:"
validate_env_pair "TEST_VAR1" "unquoted_value"
validate_env_pair "TEST_VAR2" "'single_quoted_value'"
validate_env_pair "TEST_VAR3" '"double_quoted_value"'

# Test edge cases
echo "Testing edge cases:"
validate_env_pair "EMPTY_VAR" ""
validate_env_pair "WHITESPACE_VAR" "  value_with_spaces  "

echo "✅ All validation tests completed successfully."
