#!/bin/bash

# In ~/.bashrc or ~/.zshrc (on Linux)
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
  . "$HOME/dotfiles/.shell_common.sh"
fi


# Load shared shell configuration
# Start relay
~/.local/bin/wsl-ssh-agent-relay start

# Define socket and npiperelay path using USERPROFILE for portability
export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"

# Get Windows USERPROFILE and convert to WSL path
get_npiperelay_path() {
  local userprofile=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
  echo "$(wslpath "$userprofile")/scoop/apps/npiperelay/0.1.0/npiperelay.exe"
}

NPIPERELAY=$(get_npiperelay_path)

# Check if socket is active
is_socket_active() {
  [ -S "$SSH_AUTH_SOCK" ] && ssh-add -l >/dev/null 2>&1
}

# Only start socat if socket not alive
if ! is_socket_active; then
  rm -f "$SSH_AUTH_SOCK"
  setsid nohup socat \
    UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
    EXEC:"$NPIPERELAY //./pipe/openssh-ssh-agent" \
    >/dev/null 2>&1 &
fi
