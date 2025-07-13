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
