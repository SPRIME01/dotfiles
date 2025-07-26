# dotfiles/.zshrc
# Version: 2.0 - Zsh configuration with Oh My Zsh integration
# Last Modified: July 20, 2025

# Load shared shell configuration first
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
    source "$HOME/dotfiles/.shell_common.sh"
fi

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Oh My Zsh theme - using powerlevel10k for consistency with PowerShell Oh My Posh
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins to load (add more as needed)
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    kubectl
    npm
    node
    python
    pip
    ubuntu
    command-not-found
    history-substring-search
    colored-man-pages
)

# Load Oh My Zsh (only if it exists)
if [ -d "$ZSH" ]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "⚠️  Oh My Zsh not found. Run install_zsh.sh to install it."
    # Fallback configurations if Oh My Zsh isn't installed
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
fi

# User configuration
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='code'
fi

# Zsh-specific aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases (complement the ones in .shell_common.sh)
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
# Load additional shell functions if they exist
if [ -f "$HOME/dotfiles/.shell_functions.sh" ]; then
    source "$HOME/dotfiles/.shell_functions.sh"
fi

# Load Powerlevel10k configuration if it exists
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enhanced history search
if [[ -n "$plugins[(r)history-substring-search]" ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

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
export MCPGATEWAY_BEARER_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InNwcmltZTAxIiwiZXhwIjoxNzUzMTQ0ODQyfQ.jz_q_Klwtz8O2UYeJwfrOKvnDO0XNUzEThmUUtpFkO4"
export WSL_DISTRO_NAME="Ubuntu-24.04"
# Load MCP environment variables safely by processing only simple key=value pairs
if [ -f ~/Projects/MCPContextForge/.env ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Only process simple environment variables (no complex quoting)
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=[^\'\"]*$ ]]; then
            # Simple unquoted values
            export "$line"
        elif [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=\"[^\"]*\"$ ]]; then
            # Simple double-quoted values without nested quotes
            export "$line"
        elif [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*=\'[^\']*\'$ ]]; then
            # Simple single-quoted values without nested quotes
            export "$line"
        fi
        # Skip complex values like ALLOWED_ORIGINS that have nested quotes
    done < ~/Projects/MCPContextForge/.env
fi
# Load specific MCP environment variables safely
if [ -f ~/Projects/MCPContextForge/.env ]; then
    # Use safer method to extract values
    BEARER_TOKEN=$(grep "^MCPGATEWAY_BEARER_TOKEN=" ~/Projects/MCPContextForge/.env | cut -d"=" -f2- | sed 's/^["'\'']\(.*\)["'\'']$/\1/')
    if [ -n "$BEARER_TOKEN" ]; then
        export MCPGATEWAY_BEARER_TOKEN="$BEARER_TOKEN"
    fi
    export WSL_DISTRO_NAME="Ubuntu-24.04"
fi
# Load MCP token for Gemini CLI
export MCP_JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InNwcmltZTAxIiwiZXhwIjoxNzUzMTQ0ODQyfQ.jz_q_Klwtz8O2UYeJwfrOKvnDO0XNUzEThmUUtpFkO4"

export PATH="/snap/bin:$PATH"
