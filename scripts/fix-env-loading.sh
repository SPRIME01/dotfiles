#!/usr/bin/env bash
# Attempt to fix environment loading issues for dotfiles
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Fixing environment loading..."

# Re-link .shell_common.sh and .shell_functions.sh
ln -sf "$DOTFILES_ROOT/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES_ROOT/.shell_functions.sh" ~/.shell_functions

# Re-source in current shell if possible
if [[ $- == *i* ]]; then
  source ~/.shell_common || true
  source ~/.shell_functions || true
fi

echo "✅ Environment loading fix applied. Restart your shell."
