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