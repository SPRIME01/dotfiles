#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
# test/test-environment-loading.sh - Test environment loading functionality

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_environment_loading() {
	echo "🧪 Testing Environment Loading System"
	echo "======================================"

	# Test DOTFILES_ROOT is set correctly
	# Expect DOTFILES_ROOT to equal repo root
	local expected_root
	expected_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit && pwd)"
	test_assert "DOTFILES_ROOT is set to correct path" \
		'echo "$DOTFILES_ROOT"' \
		"$expected_root"

	# Test GEMINI_API_KEY is loaded when declared in .env
	# If there is no .env or it doesn't declare GEMINI_API_KEY, accept UNSET
	local expect_secret="UNSET"
	envfile="$(dirname "${BASH_SOURCE[0]}")/../.env"
	if [[ -f "$envfile" ]] && grep -E '^\s*GEMINI_API_KEY\s*=' "$envfile" >/dev/null 2>&1; then
		expect_secret="SET"
	fi
	test_assert "GEMINI_API_KEY is loaded" \
		'[[ -n "$GEMINI_API_KEY" ]] && echo "SET" || echo "UNSET"' \
		"$expect_secret"

	# Test PROJECTS_ROOT has default value or is overridden in .env
	local expected_projects
	expected_projects="$HOME/projects"
	envfile="$(dirname "${BASH_SOURCE[0]}")/../.env"
	if [[ -f "$envfile" ]] && grep -E '^\s*PROJECTS_ROOT\s*=' "$envfile" >/dev/null 2>&1; then
		expected_projects=$(grep -E '^\s*PROJECTS_ROOT\s*=' "$envfile" | sed -E 's/^\s*PROJECTS_ROOT\s*=\s*//')
		expected_projects=${expected_projects%\"}
		expected_projects=${expected_projects#\"}
		expected_projects=${expected_projects%\'}
		expected_projects=${expected_projects#\'}
	fi
	test_assert "PROJECTS_ROOT has default value or .env override" \
		'echo "$PROJECTS_ROOT"' \
		"$expected_projects"

	# Test platform detection
	test_assert "Platform detection works" \
		'[[ -n "$DOTFILES_PLATFORM" ]] && echo "SET" || echo "UNSET"' \
		'SET'

	# Test shell detection
	test_assert "Shell detection works" \
		'[[ -n "$DOTFILES_SHELL" ]] && echo "SET" || echo "UNSET"' \
		'SET'
}

# Run tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Ensure we're in the dotfiles directory and environment is loaded
	cd "$(dirname "$0")/.." || exit
	# Use a temporary HOME for deterministic PROJECTS_ROOT expectations
	TMP_HOME=$(mktemp -d)
	export HOME="$TMP_HOME"
	# Ensure PROJECTS_ROOT isn't inherited from the outer environment
	unset PROJECTS_ROOT 2>/dev/null || true
	trap 'rm -rf "$TMP_HOME"' EXIT
	source .shell_common.sh

	test_environment_loading
	test_summary
	exit $?
fi
