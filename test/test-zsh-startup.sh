#!/usr/bin/env bash
# shellcheck disable=SC1091
# test/test-zsh-startup.sh
# test/test-zsh-startup.sh
# Minimal test to ensure zsh startup loads without errors.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/framework.sh"

test_zsh_startup() {
	echo "🧪 Testing zsh startup"
	# Attempt to start zsh in non-interactive mode to ensure config loads
	zsh -i -c "exit" >/dev/null 2>&1 && echo "PASS: zsh started" || echo "FAIL: zsh failed to start"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	cd "$(dirname "$0")/.." || exit
	source .shell_common.sh
	test_zsh_startup
	test_summary
fi
