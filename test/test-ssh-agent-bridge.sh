#!/usr/bin/env bash
# Basic checks for SSH agent bridge; safe and skip-heavy
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Only attempt under WSL
if ! grep -qi microsoft /proc/version 2>/dev/null && [ -z "${WSL_DISTRO_NAME:-}" ]; then
	echo "⚠️ Skipping SSH agent bridge test (not WSL)"
	exit 0
fi

# Sourcing the zsh SSH script safely in bash is not appropriate; just check presence and prereqs
if [ ! -f "$REPO_ROOT/zsh/ssh-agent.zsh" ] && [ ! -f "$REPO_ROOT/scripts/setup-ssh-agent-bridge.sh" ]; then
	echo "⚠️ Skipping: SSH bridge scripts not found"
	exit 0
fi

need_missing=0
command -v socat >/dev/null 2>&1 || need_missing=1
(command -v npiperelay.exe >/dev/null 2>&1 || command -v npiperelay >/dev/null 2>&1) || need_missing=1

if [ "$need_missing" -eq 1 ]; then
	echo "⚠️ Skipping: prerequisites for SSH agent bridge are missing"
	exit 0
fi

echo "✅ SSH agent bridge prerequisites present"
