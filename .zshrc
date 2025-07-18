# Load shared shell configuration
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
    source "$HOME/dotfiles/.shell_common.sh"
fi

# Zsh-specific configurations
autoload -U compinit
compinit

# Enable command auto-correction
setopt CORRECT

# Enable extended globbing
setopt EXTENDED_GLOB

# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# === PNPM setup ===
# Set the PNPM_HOME
export PNPM_HOME="/home/sprime01/.local/share/pnpm"

# Add pnpm's *specific global executable directory for gemini-cli* to PATH (PRIORITY!)
# This path was found via 'find /home/sprime01/.local/share/pnpm/ -name gemini -type f -executable'
export PNPM_GEMINI_BIN_DIR="/home/sprime01/.local/share/pnpm/global/5/.pnpm/@google+gemini-cli@0.1.12/node_modules/@google/gemini-cli/node_modules/.bin"
case ":$PATH:" in
  *":$PNPM_GEMINI_BIN_DIR:"*) ;;
  *) export PATH="$PNPM_GEMINI_BIN_DIR:$PATH" ;; # Add to the BEGINNING of PATH
esac

# Add PNPM_HOME itself to PATH (for pnpm command itself, lower priority for binaries)
# This handles the pnpm command itself, but not necessarily all global binaries directly.
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# === PNPM end ===

# === WSL2-specific configurations ===
# Only run WSL2-specific code if we're actually in WSL2
if [[ -n "${WSL_DISTRO_NAME}" ]]; then
    # Start SSH agent relay for WSL2
    if [[ -f ~/.local/bin/wsl-ssh-agent-relay ]]; then
        ~/.local/bin/wsl-ssh-agent-relay start
    fi

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
fi

# Load additional environment if available
if [[ -f "$HOME/.local/bin/env" ]]; then
    . "$HOME/.local/bin/env"
fi
