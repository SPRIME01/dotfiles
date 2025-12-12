#!/usr/bin/env bash
# test/test-no-deprecated-loaders.sh - Test for deprecated loader references

set -euo pipefail

# Load test framework
source "$(dirname "$0")/framework.sh"
test_no_deprecated_loaders_in_shell_config() {
	echo "🧪 Testing shell config files for deprecated loader references..."

	# Common shell configuration files that might reference loaders
	local shell_config_files=(
		"$HOME/.zshrc"
		"$HOME/.bashrc"
		"$HOME/.bash_profile"
		"$HOME/.profile"
		"$HOME/.config/fish/config.fish"
		"$HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"
		"$HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
	)

	local deprecated_patterns=(
		"scripts/load_env.sh"
		"load_env.sh"
		"source.*load_env.sh"
		"\\..*load_env.sh"
	)

	local found_deprecated=0
	local found_files=()

	for config_file in "${shell_config_files[@]}"; do
		if [[ -f "$config_file" ]]; then
			for pattern in "${deprecated_patterns[@]}"; do
				if grep -q "$pattern" "$config_file" 2>/dev/null; then
					echo "❌ Found deprecated loader reference in $config_file:"
					grep -n "$pattern" "$config_file"
					found_deprecated=1
					found_files+=("$config_file")
				fi
			done
		fi
	done

	if [[ $found_deprecated -eq 0 ]]; then
		echo "✅ No deprecated loader references found in shell config files"
		return 0
	else
		echo "❌ Deprecated loader references found in: ${found_files[*]}"
		return 1
	fi
}

test_no_deprecation_warnings() {
	echo "🧪 Testing for deprecation warnings during shell startup..."

	# Test zsh startup
	local zsh_output
	zsh_output=$(zsh -c "source $HOME/.zshrc 2>&1" 2>/dev/null || true)

	if echo "$zsh_output" | grep -q -i "deprecated\|warning.*load_env"; then
		echo "❌ Deprecation warnings detected in zsh startup:"
		echo "$zsh_output" | grep -i "deprecated\|warning.*load_env"
		return 1
	fi

	# Test bash startup
	local bash_output
	bash_output=$(bash -c "source $HOME/.bashrc 2>&1" 2>/dev/null || true)

	if echo "$bash_output" | grep -q -i "deprecated\|warning.*load_env"; then
		echo "❌ Deprecation warnings detected in bash startup:"
		echo "$bash_output" | grep -i "deprecated\|warning.*load_env"
		return 1
	fi

	echo "✅ No deprecation warnings detected during shell startup"
	return 0
}

test_lib_env_loader_available() {
	echo "🧪 Testing lib/env-loader.sh availability..."

	test_assert "lib/env-loader.sh exists" \
		"[ -f \"lib/env-loader.sh\" ] && echo true || echo false" \
		"true"

	test_assert "lib/env-loader.sh is executable" \
		"[ -x \"lib/env-loader.sh\" ] && echo true || echo false" \
		"true"
}

main() {
	echo "🚀 Starting deprecated loader cleanup tests..."
	echo

	test_no_deprecated_loaders_in_shell_config
	test_no_deprecation_warnings
	test_lib_env_loader_available

	test_summary
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main
fi
