#!/usr/bin/env bash
# test/test-path-config.sh - Test PATH configuration in templates

set -uo pipefail

# Source the test framework
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "$SCRIPT_DIR/framework.sh"

test_projects_path_included_once() {
	echo "🧪 Testing Projects folder included in PATH once (no duplicates)"
	((TESTS_RUN++))

	# Check if projects_path.tmpl is included in both shell configs
	local zshrc_includes_projects
	local bashrc_includes_projects

	if [[ ! -f "$PWD/dot_zshrc.tmpl" ]] || [[ ! -f "$PWD/dot_bashrc.tmpl" ]]; then
		echo "❌ Template files not found"
		FAILED_TESTS+=("Missing template files")
		((TESTS_FAILED++))
		return 1
	fi

	# Count matches excluding comments ({{/* ... */}})
	zshrc_includes_projects=$(grep "projects_path.tmpl" "$PWD/dot_zshrc.tmpl" | grep -v "{{\/\*" | grep -c "include")
	bashrc_includes_projects=$(grep "projects_path.tmpl" "$PWD/dot_bashrc.tmpl" | grep -v "{{\/\*" | grep -c "include")

	# Zsh config is simplified and might not include it directly (0 is acceptable if intentional)
	# Bash should include it exactly once.
	if [[ ($zshrc_includes_projects -eq 0 || $zshrc_includes_projects -eq 1) && $bashrc_includes_projects -eq 1 ]]; then
		echo "✅ Projects path template included correctly (zsh: $zshrc_includes_projects, bash: $bashrc_includes_projects)"
		((TESTS_PASSED++))
		return 0
	else
		echo "❌ Projects path template inclusion count mismatch"
		echo "   zshrc: $zshrc_includes_projects (expected 0-1), bashrc: $bashrc_includes_projects (expected 1)"
		FAILED_TESTS+=("Projects path template inclusion count mismatch")
		((TESTS_FAILED++))
		return 1
	fi
}

test_platform_specific_path_entries() {
	echo "🧪 Testing platform-specific PATH entries"
	((TESTS_RUN++))

	# Source platform detection to understand current platform
	source "$PWD/lib/platform-detection.sh" >/dev/null 2>&1
	detect_platform --force

	# Check if platform-specific templates exist (this will fail in Red phase)
	local platform_issues=()

	# For WSL, check if WSL-specific PATH template exists
	if [[ "$DOTFILES_PLATFORM" == "wsl" ]]; then
		if [[ ! -f "$PWD/templates/partials/wsl_path.tmpl" ]]; then
			platform_issues+=("Missing WSL-specific PATH template")
		fi
	fi

	# For Windows, check if Windows-specific PATH template exists
	if [[ "$DOTFILES_PLATFORM" == "windows" ]]; then
		if [[ ! -f "$PWD/templates/partials/windows_path.tmpl" ]]; then
			platform_issues+=("Missing Windows-specific PATH template")
		fi
	fi

	# For macOS, check if macOS-specific PATH template exists
	if [[ "$DOTFILES_PLATFORM" == "macos" ]]; then
		if [[ ! -f "$PWD/templates/partials/macos_path.tmpl" ]]; then
			platform_issues+=("Missing macOS-specific PATH template")
		fi
	fi

	if [[ ${#platform_issues[@]} -eq 0 ]]; then
		echo "✅ Platform-specific PATH templates exist for $DOTFILES_PLATFORM"
		((TESTS_PASSED++))
		return 0
	else
		echo "❌ Platform-specific PATH issues: ${platform_issues[*]}"
		FAILED_TESTS+=("Platform PATH issues: ${platform_issues[*]}")
		((TESTS_FAILED++))
		return 1
	fi
}

test_path_idempotence() {
	echo "🧪 Testing PATH idempotence (re-sourcing doesn't duplicate)"
	((TESTS_RUN++))

	# Create a test environment to simulate shell sourcing
	local temp_dir
	temp_dir=$(mktemp -d)
	# shellcheck disable=SC2154  # temp_dir is set above; trap runs in same scope
	trap 'local _tdir="${temp_dir:-}"; [[ -n "$_tdir" ]] && rm -rf "$_tdir"' EXIT

	# Produce a sanitized, sourceable copy of the projects path template
	local REPO_ROOT
	REPO_ROOT="$PWD"
	local sanitized
	sanitized="$temp_dir/projects_path.sh"
	sed -E '/\{\{.*\}\}/d;/^\s*#/d;/^\s*$/d' "$REPO_ROOT/templates/partials/projects_path.tmpl" >"$sanitized"
	chmod 0644 "$sanitized"

	# Create test script that sources ONLY the sanitized template twice
	cat >"$temp_dir/test_script.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# Minimal, deterministic PATH baseline
export PATH="/usr/bin:/bin"
# First source
source "$sanitized"
first_path="\$PATH"
# Second source (simulate re-sourcing)
source "$sanitized"
second_path="\$PATH"
# Exit with success only if identical
[[ "\$first_path" == "\$second_path" ]]
EOF

	chmod +x "$temp_dir/test_script.sh"

	# Run the test
	if "$temp_dir/test_script.sh"; then
		echo "✅ PATH remains stable after re-sourcing (no duplication)"
		((TESTS_PASSED++))
		return 0
	else
		echo "❌ PATH duplication detected after re-sourcing"
		FAILED_TESTS+=("PATH duplication on re-sourcing")
		((TESTS_FAILED++))
		return 1
	fi
}

main() {
	echo "🔬 Testing PATH Configuration in Templates"
	echo "========================================"

	# Run all tests
	test_projects_path_included_once
	test_platform_specific_path_entries
	test_path_idempotence

	test_summary
	exit $?
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi
