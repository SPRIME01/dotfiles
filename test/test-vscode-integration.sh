#!/usr/bin/env bash
# test/test-vscode-integration.sh - Test VS Code settings integration

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test 1: Check if base settings file exists (in repo)
test_base_settings() {
	[[ -f "$DOTFILES_DIR/.config/Code/User/settings.json" ]]
}

# Test 2: Check if platform-specific settings exist
test_platform_settings() {
	[[ -f "$DOTFILES_DIR/.config/Code/User/settings.linux.json" ]] &&
		[[ -f "$DOTFILES_DIR/.config/Code/User/settings.windows.json" ]] &&
		[[ -f "$DOTFILES_DIR/.config/Code/User/settings.darwin.json" ]] &&
		[[ -f "$DOTFILES_DIR/.config/Code/User/settings.wsl.json" ]]
}

# Test 3: Check if installation script exists and is executable
test_install_script() {
	[[ -f "$DOTFILES_DIR/install/vscode.sh" ]] &&
		[[ -x "$DOTFILES_DIR/install/vscode.sh" ]]
}

# Test 4: Validate JSON syntax of base settings
test_json_syntax_base() {
	if command -v jq &>/dev/null; then
		jq empty "$DOTFILES_DIR/.config/Code/User/settings.json" 2>/dev/null
	else
		echo "⚠️ jq not available, skipping JSON validation"
		return 0
	fi
}

# Test 5: Validate JSON syntax of platform settings
test_json_syntax_platform() {
	if command -v jq &>/dev/null; then
		local result=0
		for platform in linux windows darwin wsl; do
			if ! jq empty "$DOTFILES_DIR/.config/Code/User/settings.$platform.json" 2>/dev/null; then
				echo "❌ Invalid JSON in settings.$platform.json"
				result=1
			fi
		done
		return $result
	else
		echo "⚠️ jq not available, skipping JSON validation"
		return 0
	fi
}

# Test 6: Test context detection
test_context_detection() {
	local context
	context=$(bash -c "source '$DOTFILES_DIR/install/vscode.sh'; detect_context" 2>/dev/null)
	[[ "$context" != "unknown" && -n "$context" ]]
}

# Test 7: Test dry-run of installation (without actually installing)
test_dry_run() {
	# Create a temporary directory for testing
	local temp_dir
	temp_dir=$(mktemp -d)

	# Test the script without actually modifying system files
	export HOME="$temp_dir"
	mkdir -p "$temp_dir/.config/Code/User"

	# Source the installation script and test setup function
	if bash -c "
        source '$DOTFILES_DIR/install/vscode.sh'
        setup_settings_file '$temp_dir/.config/Code/User/settings.json' 'linux'
    " 2>/dev/null; then
		# Check if the file was created
		if [[ -f "$temp_dir/.config/Code/User/settings.json" ]]; then
			rm -rf "$temp_dir"
			return 0
		fi
	fi

	rm -rf "$temp_dir"
	return 1
}

# Test 8: Test JSON merging functionality
test_json_merging() {
	if command -v jq &>/dev/null; then
		local temp_dir
		temp_dir=$(mktemp -d)

		# Create test files
		echo '{"a": 1, "b": 2}' >"$temp_dir/base.json"
		echo '{"b": 3, "c": 4}' >"$temp_dir/override.json"

		# Test merging
		jq -s '.[0] * .[1]' "$temp_dir/base.json" "$temp_dir/override.json" >"$temp_dir/merged.json"

		# Check if merge worked correctly
		local result=0
		if ! jq -e '.a == 1 and .b == 3 and .c == 4' "$temp_dir/merged.json" &>/dev/null; then
			result=1
		fi

		rm -rf "$temp_dir"
		return $result
	else
		echo "⚠️ jq not available, skipping JSON merge test"
		return 0
	fi
}

# Test 9: Check if bootstrap script includes VS Code setup
test_bootstrap_integration() {
	grep -q "vscode.sh" "$DOTFILES_DIR/bootstrap.sh"
}

# Test 10: Verify no Windows-specific paths in base settings
test_no_windows_paths() {
	if ! grep -q "C:\\\\" "$DOTFILES_DIR/.config/Code/User/settings.json" &&
		! grep -q "AppData" "$DOTFILES_DIR/.config/Code/User/settings.json"; then
		return 0
	else
		return 1
	fi
}

# Main test runner
main() {
	echo "🧪 Starting VS Code settings integration tests..."
	echo

	# Run full suite using numeric exit codes (echo $?) for framework compatibility
	test_assert "Base settings file exists" \
		'[[ -f "'$DOTFILES_DIR'/.config/Code/User/settings.json" ]]; echo $?' \
		"0"

	test_assert "Platform-specific settings exist" \
		'[[ -f "'$DOTFILES_DIR'/.config/Code/User/settings.linux.json" && -f "'$DOTFILES_DIR'/.config/Code/User/settings.windows.json" && -f "'$DOTFILES_DIR'/.config/Code/User/settings.darwin.json" && -f "'$DOTFILES_DIR'/.config/Code/User/settings.wsl.json" ]]; echo $?' \
		"0"

	test_assert "Installation script is executable" \
		'[[ -x "'$DOTFILES_DIR'/install/vscode.sh" ]]; echo $?' \
		"0"

	test_assert "Base settings JSON syntax is valid" \
		'if command -v jq >/dev/null 2>&1; then jq empty "'$DOTFILES_DIR'/.config/Code/User/settings.json" >/dev/null 2>&1; echo $?; else echo 0; fi' \
		"0"

	test_assert "Platform settings JSON syntax is valid" \
		'if command -v jq >/dev/null 2>&1; then ok=0; for p in linux windows darwin wsl; do jq empty "'$DOTFILES_DIR'/.config/Code/User/settings.$p.json" >/dev/null 2>&1 || ok=1; done; if [[ $ok -eq 0 ]]; then echo 0; else echo 1; fi; else echo 0; fi' \
		"0"

	test_assert "Context detection works" \
		'source "'$DOTFILES_DIR'/install/vscode.sh" >/dev/null 2>&1; c=$(detect_context); [[ -n "$c" && "$c" != "unknown" ]]; echo $?' \
		"0"

	test_assert "Dry-run installation works" \
		'test_dry_run >/dev/null 2>&1; echo $?' \
		"0"

	test_assert "JSON merging functionality works" \
		'test_json_merging >/dev/null 2>&1; echo $?' \
		"0"

	test_assert "Bootstrap script includes VS Code setup" \
		'grep -Eq "(install/)?vscode.sh|bootstrap_vscode" "'$DOTFILES_DIR'/bootstrap.sh" >/dev/null 2>&1; echo $?' \
		"0"

	test_assert "Base settings have no Windows-specific paths" \
		'(! grep -q "C:\\\\" "'$DOTFILES_DIR'/.config/Code/User/settings.json" && ! grep -q "AppData" "'$DOTFILES_DIR'/.config/Code/User/settings.json"); echo $?' \
		"0"

	test_summary
	exit $?
}

# Run main function
main "$@"
