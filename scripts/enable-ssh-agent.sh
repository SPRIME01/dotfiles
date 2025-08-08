#!/usr/bin/env bash
# Enable SSH agent in zsh (after installing npiperelay)
set -euo pipefail

echo "🔑 Enabling SSH agent in zsh..."

ZSHRC="$HOME/.zshrc"
# Match any SSH agent bridge script reference (handles custom script names)
if grep -E -q 'ssh-agent.*bridge.*\.sh' "$ZSHRC"; then
  sed -i -E '/ssh-agent.*bridge.*\.sh/s/^# *//' "$ZSHRC"
  echo "✅ SSH agent bridge enabled in .zshrc. Restart your shell."
else
  echo "⚠️  No SSH agent bridge line found in .zshrc."
  echo "   If you use a custom SSH agent setup, please add or uncomment the relevant line manually."
fi
