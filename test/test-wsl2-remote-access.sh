#!/usr/bin/env bash
# test-wsl2-remote-access.sh - Tests for setup-wsl2-remote-access.sh
# Covers script structure, help output, and argument parsing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/framework.sh"

SCRIPT_UNDER_TEST="$DOTFILES_ROOT/scripts/setup-wsl2-remote-access.sh"

echo "🧪 Testing setup-wsl2-remote-access.sh"
echo "======================================="
echo ""

# Test 1: Script exists and is executable
test_assert "Script exists" \
	"[[ -f '$SCRIPT_UNDER_TEST' ]] && echo 'exists'" \
	"exists"

test_assert "Script is executable" \
	"[[ -x '$SCRIPT_UNDER_TEST' ]] && echo 'executable'" \
	"executable"

# Test 2: Script has proper shebang
test_assert "Script has bash shebang" \
	"head -1 '$SCRIPT_UNDER_TEST' | grep -q '#!/usr/bin/env bash' && echo 'ok'" \
	"ok"

# Test 3: Script uses strict mode
test_assert "Script uses set -euo pipefail" \
	"grep -q 'set -euo pipefail' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

# Test 4: Help option works (doesn't require WSL)
help_output=$(bash "$SCRIPT_UNDER_TEST" --help 2>&1 || true)
test_assert_contains "Help shows usage info" "$help_output" "bash scripts/setup-wsl2-remote-access.sh"
test_assert_contains "Help mentions Tailscale SSH" "$help_output" "Tailscale SSH"

# Test 5: Script has Tailscale setup function
test_assert "Has Tailscale SSH function" \
	"grep -q 'setup_tailscale_ssh()' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

# Test 6: Script checks for WSL environment
test_assert "Checks for WSL_DISTRO_NAME" \
	"grep -q 'WSL_DISTRO_NAME' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

# Test 7: Script supports TAILSCALE_AUTH_KEY
test_assert "Supports TAILSCALE_AUTH_KEY environment variable" \
	"grep -q 'TAILSCALE_AUTH_KEY' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

# Test 8: Invalid option handling - test outside WSL
invalid_output=$(bash "$SCRIPT_UNDER_TEST" --invalid 2>&1 || true)
test_assert_contains "Invalid option shows error" "$invalid_output" "Unknown option"

# Test 9: Script integrates with dotfiles structure
test_assert "References install-tailscale.sh" \
	"grep -q 'install-tailscale.sh' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

# Test 10: Script mentions VS Code Remote SSH setup
test_assert "Mentions VS Code Remote SSH" \
	"grep -q 'VS Code' '$SCRIPT_UNDER_TEST' && echo 'ok'" \
	"ok"

echo ""
test_summary
