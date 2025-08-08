#!/usr/bin/env bash
# Attempt to fix environment loading issues for dotfiles
set -euo pipefail

echo "🔧 Fixing environment loading..."

# Re-link .shell_common.sh and .shell_functions.sh
DOTFILES="$HOME/dotfiles"
ln -sf "$DOTFILES/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES/.shell_functions.sh" ~/.shell_functions

# Re-source in current shell if possible
if [[ $- == *i* ]]; then
  source ~/.shell_common || true
  source ~/.shell_functions || true
fi

echo "✅ Environment loading fix applied. Restart your shell."
