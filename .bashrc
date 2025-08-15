#!/bin/bash

# Resolve DOTFILES_ROOT once for consistency across shells (allow override)
DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export DOTFILES_ROOT

# Source shared configuration and helper scripts (readable check)
if [ -r "$DOTFILES_ROOT/.shell_common.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/.shell_common.sh"
fi

# Load the environment loader and import variables from .env if it exists.
if [ -r "$DOTFILES_ROOT/lib/env-loader.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/lib/env-loader.sh"
  load_dotfiles_environment "$DOTFILES_ROOT" || true
elif [ -r "$DOTFILES_ROOT/scripts/load_env.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/scripts/load_env.sh"
  # Fallback: legacy/simple loader if present
  command -v load_env_file >/dev/null 2>&1 && load_env_file "$DOTFILES_ROOT/.env" || true
fi

# Set up SSH agent bridging in WSL2 (idempotent)
if [ -r "$DOTFILES_ROOT/scripts/setup-ssh-agent-bridge.sh" ]; then
  # shellcheck source=/dev/null
  . "$DOTFILES_ROOT/scripts/setup-ssh-agent-bridge.sh"
fi

# Volta PATH (idempotent; only if it exists)
export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
if [ -d "$VOLTA_HOME/bin" ]; then
  case ":$PATH:" in
    *":$VOLTA_HOME/bin:"*) ;; # already present
    *) PATH="$VOLTA_HOME/bin:$PATH" ;;
  esac
fi

# Common user bins (~/.local/bin, ~/.cargo/bin) — prepend so user-installed bins take precedence
for _p in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
  if [ -d "$_p" ] && [[ ":$PATH:" != *":$_p:"* ]]; then
    PATH="$_p:$PATH"
  fi
done

# Export PATH once after all modifications
export PATH

# Optional debug tracing
if [ "${DOTFILES_DEBUG:-0}" = "1" ]; then
  echo "[dotfiles] bash profile loaded (DOTFILES_ROOT=$DOTFILES_ROOT, SHELL=$SHELL)"
fi
