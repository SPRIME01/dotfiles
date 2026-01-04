#!/usr/bin/env bash
# test/test-mise-adoption.sh - Test Mise adoption and Volta deprecation

set -uo pipefail

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_no_volta_references() {
	echo "🧪 Testing no Volta references in shell configs"
	((TESTS_RUN++))

	# Files that should NOT contain Volta PATH injection
	local checked_files=(
		".zshrc"
		".shell_common.sh"
		".shell_init.sh"
		"shell/common/environment.sh"
		"lib/env-loader.sh"
		"zsh/path.zsh"
		".envrc"
	)

	local ok=true

	for file in "${checked_files[@]}"; do
		if [[ -f "$file" ]] && grep -Eq "VOLTA_HOME.*PATH|PATH.*VOLTA_HOME|VOLTA_HOME.*bin" "$file"; then
			echo "❌ Volta PATH injection found in $file (should be removed)"
			FAILED_TESTS+=("Volta reference in $file")
			((TESTS_FAILED++))
			ok=false
		fi
	done

	if [[ "$ok" == true ]]; then
		echo "✅ No Volta references found in shell configs"
		((TESTS_PASSED++))
		return 0
	fi

	return 1
}

test_pnpm_in_mise_config() {
	echo "🧪 Testing pnpm is configured in mise"
	((TESTS_RUN++))

	if [[ ! -f "dot_mise.toml" ]]; then
		echo "❌ dot_mise.toml not found"
		FAILED_TESTS+=("dot_mise.toml missing")
		((TESTS_FAILED++))
		return 1
	fi

	if grep -q 'pnpm' "dot_mise.toml"; then
		echo "✅ pnpm is configured in mise"
		((TESTS_PASSED++))
		return 0
	else
		echo "❌ pnpm not found in dot_mise.toml"
		FAILED_TESTS+=("pnpm not in mise config")
		((TESTS_FAILED++))
		return 1
	fi
}

test_mise_config_present() {
	echo "🧪 Testing mise config file presence"
	((TESTS_RUN++))

	# Skip if chezmoi is not installed
	if ! command -v chezmoi >/dev/null 2>&1; then
		echo "⚠️  chezmoi not installed, skipping config presence test"
		((TESTS_SKIPPED++))
		return 0
	fi

	# Check if dot_mise.toml template exists
	if [[ ! -f "dot_mise.toml" ]]; then
		echo "❌ dot_mise.toml template not found"
		FAILED_TESTS+=("dot_mise.toml template missing")
		((TESTS_FAILED++))
		return 1
	fi

	# Verify mapping using target-path resolution
	local target
	target=$(chezmoi target-path --source "$PWD" --source-path dot_mise.toml 2>/dev/null || true)
	if [[ "$target" == "$HOME/.mise.toml" ]]; then
		echo "✅ mise config file maps to $target"
		((TESTS_PASSED++))
		return 0
	else
		echo "❌ mise config mapping incorrect (got: $target)"
		FAILED_TESTS+=("mise config mapping incorrect")
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

	# Create tmpdir safely and install a guarded cleanup trap
	local tmpdest
	if ! tmpdest="$(mktemp -d)"; then
		echo "❌ failed to create temp dir for mise dry-run"
		FAILED_TESTS+=("mise dry-run - mktemp failed")
		((TESTS_FAILED++))
		return 1
	fi
	trap '[[ -n "$tmpdest" ]] && rm -rf -- "$tmpdest"' RETURN

	if ! chezmoi apply --source "$PWD" --destination "$tmpdest" --force >/dev/null 2>&1; then
		echo "❌ failed to render .mise.toml to temp destination"
		FAILED_TESTS+=("mise dry-run - render failed")
		((TESTS_FAILED++))
		return 1
	fi

	if MISE_CONFIG_FILE="$tmpdest/.mise.toml" MISE_DATA_DIR="$tmpdest/.local/share/mise" \
		mise install --dry-run >/dev/null 2>&1; then
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

	# Render config to a temp destination (mktemp guarded)
	local tmpdest
	if ! tmpdest="$(mktemp -d)"; then
		echo "❌ failed to create temp dir for mise idempotence test"
		FAILED_TESTS+=("mise idempotence - mktemp failed")
		((TESTS_FAILED++))
		return 1
	fi
	# shellcheck disable=SC2154  # tmpdest is set above; trap runs in same scope
	trap 'local _tmp="${tmpdest:-}"; [[ -n "$_tmp" ]] && rm -rf -- "$_tmp"; trap - RETURN' RETURN
	if ! chezmoi apply --source "$PWD" --destination "$tmpdest" --force >/dev/null 2>&1; then
		echo "❌ failed to render .mise.toml to temp destination"
		FAILED_TESTS+=("mise idempotence - render failed")
		((TESTS_FAILED++))
		return 1
	fi

	# First run - capture output and exit code without letting set -e abort
	local first_output='' first_exit_code=0
	if ! first_output="$(MISE_CONFIG_FILE="$tmpdest/.mise.toml" \
		MISE_DATA_DIR="$tmpdest/.local/share/mise" \
		mise install 2>&1)"; then
		first_exit_code=$?
	fi

	# Second run - should be no-op
	local second_output='' second_exit_code=0
	if ! second_output="$(MISE_CONFIG_FILE="$tmpdest/.mise.toml" \
		MISE_DATA_DIR="$tmpdest/.local/share/mise" \
		mise install 2>&1)"; then
		second_exit_code=$?
	fi

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
	echo "🔬 Testing Mise Standardization (Volta Removed)"
	echo "================================================"

	# Run all tests
	test_no_volta_references
	test_pnpm_in_mise_config
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
