#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=test/framework.sh
source "$ROOT_DIR/test/framework.sh"

if ! command -v zsh >/dev/null 2>&1; then
	echo "SKIP: zsh not installed"
	((++TESTS_SKIPPED))
	test_summary
	exit 0
fi

tmp_dir="$(mktemp -d)"
cleanup() {
	rm -rf "$tmp_dir"
}
trap cleanup EXIT

cat >"$tmp_dir/.zshrc" <<EOF
export DOTFILES_ROOT="$ROOT_DIR"
source "$ROOT_DIR/.shell_init.sh"
EOF

output="$(ZDOTDIR="$tmp_dir" TERM_PROGRAM="" zsh -i -c 'exit' 2>&1)"
test_assert_equal "zsh init should not produce output" "$output" ""

test_summary
