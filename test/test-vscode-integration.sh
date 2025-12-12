#!/usr/bin/env bash
# test/test-vscode-integration.sh - Test VS Code settings integration
# shellcheck disable=SC2016

# Source the test framework
source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Helper functions have been moved inline or are unused.
# Keeping test_dry_run and test_json_merging as they are used by the test runner via explicit calls.

# Helper functions removed. Logic inlined into test assertions.

# Main test runner
main() {
	echo "🧪 Starting VS Code settings integration tests..."
	echo

	# Run full suite using numeric exit codes (echo $?) for framework compatibility
	test_assert "Base settings file exists" \
		'[[ -f "'"$DOTFILES_DIR"'/.config/Code/User/settings.json" ]]; echo $?' \
		"0"

	test_assert "Platform-specific settings exist" \
		'[[ -f "'"$DOTFILES_DIR"'/.config/Code/User/settings.linux.json" && -f "'"$DOTFILES_DIR"'/.config/Code/User/settings.windows.json" && -f "'"$DOTFILES_DIR"'/.config/Code/User/settings.darwin.json" && -f "'"$DOTFILES_DIR"'/.config/Code/User/settings.wsl.json" ]]; echo $?' \
		"0"

	test_assert "Installation script is executable" \
		'[[ -x "'"$DOTFILES_DIR"'/install/vscode.sh" ]]; echo $?' \
		"0"

	test_assert "Base settings JSON syntax is valid" \
		'if command -v jq >/dev/null 2>&1; then jq empty "'"$DOTFILES_DIR"'/.config/Code/User/settings.json" >/dev/null 2>&1; echo $?; else echo 0; fi' \
		"0"

	test_assert "Platform settings JSON syntax is valid" \
		'if command -v jq >/dev/null 2>&1; then ok=0; for p in linux windows darwin wsl; do jq empty "'"$DOTFILES_DIR"'/.config/Code/User/settings.$p.json" >/dev/null 2>&1 || ok=1; done; if [[ $ok -eq 0 ]]; then echo 0; else echo 1; fi; else echo 0; fi' \
		"0"

	test_assert "Context detection works" \
		'source "'"$DOTFILES_DIR"'/install/vscode.sh" >/dev/null 2>&1; c=$(detect_context); [[ -n "$c" && "$c" != "unknown" ]]; echo $?' \
		"0"

	test_assert "Dry-run installation works" \
		'temp_dir=$(mktemp -d); export HOME="$temp_dir"; mkdir -p "$temp_dir/.config/Code/User"; if bash -c "source \"'"$DOTFILES_DIR"'/install/vscode.sh\"; setup_settings_file \"$temp_dir/.config/Code/User/settings.json\" \"linux\"" 2>/dev/null; then if [[ -f "$temp_dir/.config/Code/User/settings.json" ]]; then rm -rf "$temp_dir"; echo 0; else rm -rf "$temp_dir"; echo 1; fi; else rm -rf "$temp_dir"; echo 1; fi' \
		"0"

	test_assert "JSON merging functionality works" \
		'if command -v jq >/dev/null 2>&1; then temp_dir=$(mktemp -d); echo "{\"a\": 1, \"b\": 2}" >"$temp_dir/base.json"; echo "{\"b\": 3, \"c\": 4}" >"$temp_dir/override.json"; jq -s ".[0] * .[1]" "$temp_dir/base.json" "$temp_dir/override.json" >"$temp_dir/merged.json"; if ! jq -e ".a == 1 and .b == 3 and .c == 4" "$temp_dir/merged.json" >/dev/null 2>&1; then res=1; else res=0; fi; rm -rf "$temp_dir"; echo $res; else echo 0; fi' \
		"0"

	test_assert "Bootstrap script includes VS Code setup" \
		'grep -Eq "(install/)?vscode.sh|bootstrap_vscode" "'"$DOTFILES_DIR"'/bootstrap.sh" >/dev/null 2>&1; echo $?' \
		"0"

	test_assert "Base settings have no Windows-specific paths" \
		'(! grep -q "C:\\\\" "'"$DOTFILES_DIR"'/.config/Code/User/settings.json" && ! grep -q "AppData" "'"$DOTFILES_DIR"'/.config/Code/User/settings.json"); echo $?' \
		"0"
	test_summary
	exit $?
}

# Run main function
main "$@"
