#!/usr/bin/env bash
# Enable SSH agent in zsh (after installing npiperelay)
set -euo pipefail

echo "🔑 Enabling SSH agent in zsh..."

ZSHRC="$HOME/.zshrc"
if grep -q 'setup-ssh-agent-bridge.sh' "$ZSHRC"; then
  sed -i '/setup-ssh-agent-bridge.sh/s/^# *//' "$ZSHRC"
  echo "✅ SSH agent bridge enabled in .zshrc. Restart your shell."
else
  echo "⚠️  No SSH agent bridge line found in .zshrc. Please add or uncomment manually."
fi
