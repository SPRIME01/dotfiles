#!/usr/bin/env bash
# SSH agent bridge tests for Phase 4 integration
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit && pwd)"
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

# Phase 4 tests - SSH Agent Bridge Integration via Templates
echo
echo "== Phase 4: SSH Agent Bridge Integration Tests =="

# Test 1: Check SSH_AUTH_SOCK is exported in WSL environment
echo "Test 1: SSH_AUTH_SOCK environment variable"
if [ -n "${WSL_DISTRO_NAME:-}" ]; then
    if [ -n "${SSH_AUTH_SOCK:-}" ]; then
        echo "✅ SSH_AUTH_SOCK is set: $SSH_AUTH_SOCK"
    else
        echo "⚠️ SSH_AUTH_SOCK is not set (may be normal if bridge not running)"
    fi
fi

# Test 2: Check preflight.sh helper exists and is accessible
echo
echo "Test 2: Preflight helper script"
PREFLIGHT_SCRIPT=""
for cand in "$REPO_ROOT/ssh-agent-bridge/preflight.sh" "$REPO_ROOT/scripts/ssh-agent-bridge/preflight.sh"; do
    if [ -f "$cand" ]; then
        PREFLIGHT_SCRIPT="$cand"
        break
    fi
done

if [ -n "$PREFLIGHT_SCRIPT" ]; then
    echo "✅ Preflight script exists: $PREFLIGHT_SCRIPT"
    if [ -x "$PREFLIGHT_SCRIPT" ]; then
        echo "✅ Preflight script is executable"
    else
        echo "⚠️ Preflight script is not executable"
    fi
else
    echo "❌ Preflight script missing: $PREFLIGHT_SCRIPT"
    exit 1
fi

# Test 3: Verify templates reference the SSH agent bridge partial
echo
echo "Test 3: Template references to SSH agent bridge"
TEMPLATES=("$REPO_ROOT/dot_zshrc.tmpl" "$REPO_ROOT/dot_bashrc.tmpl")
for template in "${TEMPLATES[@]}"; do
    if [ -f "$template" ]; then
        if grep -q "ssh_agent_bridge" "$template"; then
            echo "✅ $template references SSH agent bridge"
        else
            echo "❌ $template does not reference SSH agent bridge"
            exit 1
        fi
    fi
done

# Test 4: Check bridge tools availability without hard failure
echo
echo "Test 4: Graceful handling of missing bridge tools"
if command -v socat >/dev/null 2>&1 && (command -v npiperelay.exe >/dev/null 2>&1 || command -v npiperelay >/dev/null 2>&1); then
    echo "✅ Bridge tools available"
    # Test actual bridge functionality
    if ssh-add -l >/dev/null 2>&1; then
        echo "✅ SSH agent bridge is functional"
    else
        echo "⚠️ SSH agent bridge tools available but bridge may not be running"
    fi
else
    echo "⚠️ Bridge tools missing but test continues (no hard dependency)"
fi

echo
echo "✅ Phase 4 SSH agent bridge integration tests completed"
