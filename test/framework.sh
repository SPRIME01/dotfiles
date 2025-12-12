#!/usr/bin/env bash
# test/framework.sh - Test framework implementation

# Test counters
declare -i TESTS_RUN=0
declare -i TESTS_PASSED=0
declare -i TESTS_FAILED=0
declare -a FAILED_TESTS=()
declare -i TESTS_SKIPPED=0

test_assert() {
	local description="$1"
	local command="$2"
	local expected="$3"

	((++TESTS_RUN))
	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] BEGIN: $description"; fi

	local raw_actual exit_code
	# Preserve current shell flags and neutralize them during command eval
	local had_e=0 had_u=0 had_x=0
	case $- in
	*e*) had_e=1 ;;
	esac
	case $- in
	*u*) had_u=1 ;;
	esac
	case $- in
	*x*) had_x=1 ;;
	esac

	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] flags: e=$had_e u=$had_u x=$had_x"; fi
	# Disable errexit, nounset, and xtrace so evaluated commands can't abort the test runner
	set +e
	set +u
	set +x
	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] eval: $command"; fi
	raw_actual="$(eval "$command" 2>&1)"
	exit_code=$?
	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] exit_code=$exit_code raw_actual=[$raw_actual]"; fi
	# Restore previous flags
	((had_e)) && set -e || set +e
	((had_u)) && set -u || set +u
	((had_x)) && set -x || set +x
	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] flags restored"; fi

	# Sanitize output: remove bash xtrace/trace prefixes (lines that start with '+')
	# and take the last non-empty line. This keeps assertions robust when sourced
	# modules enable 'set -x' which writes traced commands to stderr (captured).
	local actual
	actual="$(printf '%s\n' "$raw_actual" | sed '/^[+]/d' | awk 'NF{line=$0} END{print line}')"
	# Fallback to raw output if sanitization yields empty string
	if [[ -z "${actual:-}" ]]; then
		actual="$raw_actual"
	fi
	# If still empty and expected looks like a numeric (exit-code style), synthesize actual from exit_code
	if [[ -z "${actual:-}" ]] && [[ "$expected" =~ ^[0-9]+$ ]]; then
		actual="$exit_code"
	fi
	if [[ -n "${TEST_DEBUG:-}" ]]; then echo "[test_assert] compare: expected=[$expected] actual=[$actual] exit=$exit_code"; fi

	if [[ "$actual" == "$expected" && $exit_code -eq 0 ]]; then
		echo "✅ $description"
		((++TESTS_PASSED))
		return 0
	else
		echo "❌ $description"
		echo "   Expected: $expected"
		echo "   Actual: $actual"
		echo "   Exit code: $exit_code"
		FAILED_TESTS+=("$description")
		((++TESTS_FAILED))
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

	((++TESTS_RUN))

	if [[ "$actual" != "$expected" ]]; then
		echo "✅ $description"
		((++TESTS_PASSED))
		return 0
	else
		echo "❌ $description"
		echo "   Expected: not '$expected'"
		echo "   Actual: '$actual'"
		FAILED_TESTS+=("$description")
		((++TESTS_FAILED))
		return 1
	fi
}

test_assert_contains() {
	local description="$1"
	local haystack="$2"
	local needle="$3"

	((++TESTS_RUN))

	# Normalize haystack: strip ANSI colors and carriage returns
	haystack="$(printf '%s' "$haystack" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' | tr -d '\r')"

	if [[ "$haystack" == *"$needle"* ]]; then
		echo "✅ $description"
		((++TESTS_PASSED))
		return 0
	else
		echo "❌ $description"
		echo "   Expected to contain: $needle"
		echo "   Actual: $haystack"
		FAILED_TESTS+=("$description")
		((++TESTS_FAILED))
		return 1
	fi
}

test_assert_matches() {
	local description="$1"
	local text="$2"
	local pattern="$3"

	((++TESTS_RUN))

	if [[ "$text" =~ $pattern ]]; then
		echo "✅ $description"
		((++TESTS_PASSED))
		return 0
	else
		echo "❌ $description"
		echo "   Expected to match pattern: $pattern"
		echo "   Actual: $text"
		FAILED_TESTS+=("$description")
		((++TESTS_FAILED))
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
	echo "Tests skipped: $TESTS_SKIPPED"

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
