#!/bin/bash

# Source shared configuration and helper scripts
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
  . "$HOME/dotfiles/.shell_common.sh"
fi

# Set up SSH agent bridging in WSL2 (idempotent)
if [ -f "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh" ]; then
  # shellcheck source=dotfiles-main/scripts/setup-ssh-agent-bridge.sh
  . "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh"
fi

# Volta home directory export (PATH management now handled by templates)
if [ -d "$HOME/.volta" ]; then
  export VOLTA_HOME="$HOME/.volta"
fi

