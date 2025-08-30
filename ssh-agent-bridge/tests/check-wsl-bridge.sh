#!/usr/bin/env bash
set -euo pipefail
echo "WSL kernel: $(uname -r)"
echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-<unset>}"
echo "Agent keys:"
ssh-add -l || true
echo "Try GitHub test (won't fail build if not set):"
ssh -T git@github.com || true
