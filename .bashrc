#!/bin/bash

# Source shared configuration and helper scripts
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
  . "$HOME/dotfiles/.shell_common.sh"
fi

# Load the environment loader and import variables from .env if it exists.
if [ -f "$HOME/dotfiles/scripts/load_env.sh" ]; then
  # shellcheck source=dotfiles-main/scripts/load_env.sh
  . "$HOME/dotfiles/scripts/load_env.sh"
  load_env_file "$HOME/dotfiles/.env"
fi

# Set up SSH agent bridging in WSL2 (idempotent)
if [ -f "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh" ]; then
  # shellcheck source=dotfiles-main/scripts/setup-ssh-agent-bridge.sh
  . "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh"
fi

# Volta and PATH management — ensure VOLTA_HOME is set then prepend common user bins
export VOLTA_HOME="$HOME/.volta"

# Prepend common user bin dirs so user-installed tools take precedence over system binaries.
# Order: Volta first, then ~/.local/bin, then ~/.cargo/bin.
for _p in "$VOLTA_HOME/bin" "$HOME/.local/bin" "$HOME/.cargo/bin"; do
  if [ -d "$_p" ] && [[ ":$PATH:" != *":$_p:"* ]]; then
    PATH="$_p:$PATH"
  fi
done

export PATH

