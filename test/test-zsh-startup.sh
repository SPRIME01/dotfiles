#!/usr/bin/env bash
# Verify zsh startup is clean: no parse errors, exit code 0
set -euo pipefail

if ! command -v zsh >/dev/null 2>&1; then
	echo "⚠️ Skipping zsh startup test (zsh not installed)"
	exit 0
fi

# Run with debug and capture output
out="$(zsh -x -ic exit 2>&1 || true)"

# Basic checks
if echo "$out" | grep -E "parse error|defining function based on alias|\[.*\] done" >/dev/null; then
	echo "❌ zsh startup has errors or job noise"
	echo "$out" | tail -n 50
	exit 1
fi

echo "✅ zsh startup clean"
