#!/usr/bin/env bash
# Launch VS Code with full shell environment
# This ensures MCP servers can access environment variables

# Source the dotfiles environment
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"
if [[ -f "$DOTFILES_ROOT/lib/env-loader.sh" ]]; then
	source "$DOTFILES_ROOT/lib/env-loader.sh"
	load_dotfiles_environment "$DOTFILES_ROOT"
fi

# Launch VS Code with inherited environment
exec code "$@"
