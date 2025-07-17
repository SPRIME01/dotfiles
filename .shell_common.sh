#!/bin/bash
# --- Global Pathing Configuration ---
# Set root paths based on the home directory for portability
export PROJECTS_ROOT="$HOME/Projects"
export DOTFILES_ROOT="$HOME/dotfiles"

# --- MCP (Model Context Protocol) Configuration ---
export MCP_ENV_PATH="$DOTFILES_ROOT/mcp/.env"
if [ -f "$MCP_ENV_PATH" ]; then
    # Source MCP environment variables
    # shellcheck source=mcp/.env
    set -a  # Automatically export all variables
    source "$MCP_ENV_PATH"
    set +a  # Disable automatic export
fi

# --- Node.js Version Management (Volta) ---
if [ -d "$HOME/.volta" ]; then
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"
fi

# --- Aliases ---
alias projects='cd "$PROJECTS_ROOT"'
# Clarified dotfiles alias for a standard repo in $HOME/dotfiles
alias dotfiles='git --git-dir="$DOTFILES_ROOT/.git" --work-tree="$DOTFILES_ROOT"'

# --- Conditional Aliases ---
if command -v code >/dev/null; then
  alias pcode='code -n "$PROJECTS_ROOT" --disable-extensions'
fi

# --- Shell-Specific Greetings ---
if [ -n "$BASH_VERSION" ]; then
  echo "👋 Welcome back, Bash commander."
elif [ -n "$ZSH_VERSION" ]; then
  echo "✨ All hail the Zsh wizard."
fi

# --- Hostname-Specific Configuration ---
case "$(hostname | tr '[:upper:]' '[:lower:]')" in
  workstation-name)
    export SPECIAL_VAR="true"
    echo "🔒 Loaded workstation-specific config for $(hostname)"
    ;;
  dev-laptop)
    export SPECIAL_VAR="false"
    echo "🔒 Loaded dev laptop config for $(hostname)"
    ;;
  *)
    echo "ℹ️  No specific config for $(hostname), loading defaults."
    ;;
esac


