#!/usr/bin/env bash
# test/test-mise-adoption.sh - Test Mise adoption and Volta deprecation

set -uo pipefail

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_volta_path_managed_centrally() {
	echo "🧪 Testing Volta PATH management is centralized"
	((TESTS_RUN++))

	local required_files=(
		"shell/common/environment.sh"
		"shell/common/environment.ps1"
		"lib/env-loader.sh"
		"PowerShell/Utils/Load-Env.ps1"
	)

	local ok=true

	for file in "${required_files[@]}"; do
		if [[ ! -f "$file" ]]; then
			echo "❌ Required Volta integration file missing: $file"
			FAILED_TESTS+=("Missing Volta integration file: $file")
			((TESTS_FAILED++))
			ok=false
		fi
	done

	if [[ "$ok" == true ]]; then
		local shell_file="shell/common/environment.sh"
		if ! grep -q "VOLTA_HOME" "$shell_file" || ! grep -q "VOLTA_HOME/bin" "$shell_file"; then
			echo "❌ $shell_file missing Volta PATH logic"
			FAILED_TESTS+=("Volta PATH missing in $shell_file")
			((TESTS_FAILED++))
			ok=false
		fi

		local ps_file="shell/common/environment.ps1"
		if ! grep -q "VOLTA_HOME" "$ps_file" || { ! grep -q "voltaBin;\$env:PATH" "$ps_file" && ! grep -q "Add-PathIfMissing.*voltaBin" "$ps_file"; }; then
			echo "❌ $ps_file missing Volta PATH logic"
			FAILED_TESTS+=("Volta PATH missing in $ps_file")
			((TESTS_FAILED++))
			ok=false
		fi
	fi

	# Ensure legacy files no longer inject Volta directly into PATH
	local disallowed_files=(
		".shell_common.sh"
		"zsh/path.zsh"
		".envrc"
	)

	for file in "${disallowed_files[@]}"; do
		if [[ -f "$file" ]] && grep -Eq "VOLTA_HOME.*PATH|PATH.*VOLTA_HOME" "$file"; then
			echo "❌ Legacy Volta PATH injection still present in $file"
			FAILED_TESTS+=("Legacy Volta PATH injection in $file")
			((TESTS_FAILED++))
			ok=false
		fi
	done

	if [[ "$ok" == true ]]; then
		echo "✅ Volta PATH is managed centrally"
		((TESTS_PASSED++))
		return 0
	fi

	return 1
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
	trap 'tmp=${tmpdest:-}; [[ -n "$tmp" ]] && rm -rf -- "$tmp"; trap - RETURN' RETURN
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
	echo "🔬 Testing Mise Adoption and Volta Deprecation"
	echo "=============================================="

	# Run all tests
	test_volta_path_managed_centrally
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
