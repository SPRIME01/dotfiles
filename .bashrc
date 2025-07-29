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
