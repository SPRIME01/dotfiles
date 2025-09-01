#!/usr/bin/env bash
# test/framework.sh - Test framework implementation

# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -a FAILED_TESTS=()

test_assert() {
	local description="$1"
	local command="$2"
	local expected="$3"

	((TESTS_RUN++))

	local raw_actual
	# Ensure any inherited xtrace doesn't pollute command output by disabling it
	# for the duration of the evaluated command.
	# Run in a subshell with xtrace disabled; also disable errexit locally to always capture exit status/output.
	raw_actual="$( (
		set +e
		set +x
		eval "$command"
	) 2>&1)"
	local exit_code=$?

	# Sanitize output: remove bash xtrace/trace prefixes (lines that start with '+')
	# and take the last non-empty line. This keeps assertions robust when sourced
	# modules enable 'set -x' which writes traced commands to stderr (captured).
	local actual
	actual="$(printf '%s
' "$raw_actual" | sed '/^[+]/d' | awk 'NF{line=$0} END{print line}')"
	# Fallback to raw output if sanitization yields empty string
	if [[ -z "${actual:-}" ]]; then
		actual="$raw_actual"
	fi

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

test_assert_equal() {
	local description="$1"
	local actual="$2"
	local expected="$3"

	test_assert "$description" "echo '$actual'" "$expected"
}

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
