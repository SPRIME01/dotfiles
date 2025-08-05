# Suppress instant prompt warnings - must be set before instant prompt initialization
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#!/usr/bin/env zsh
# dotfiles/.zshrc
#
# This zsh configuration is intentionally minimal.  It sources common
# configuration shared between shells, loads environment variables and
# plugins from modular files under `zsh/`, and then initialises Oh My Zsh.
# Additional configuration can be placed in the files within `zsh/`.

# Always source the shared shell configuration first to set PROJECTS_ROOT,
# DOTFILES_ROOT and other global aliases.
if [ -f "$HOME/dotfiles/.shell_common.sh" ]; then
    . "$HOME/dotfiles/.shell_common.sh"
fi

# Define the path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Load environment variables and additional settings from .env
if [ -f "$HOME/dotfiles/zsh/env.zsh" ]; then
    . "$HOME/dotfiles/zsh/env.zsh"
fi

# Configure PATH and add package manager binaries
if [ -f "$HOME/dotfiles/zsh/path.zsh" ]; then
    . "$HOME/dotfiles/zsh/path.zsh"
fi

# Load plugin definitions
if [ -f "$HOME/dotfiles/zsh/plugins.zsh" ]; then
    . "$HOME/dotfiles/zsh/plugins.zsh"
fi

# Configure the prompt and theme
if [ -f "$HOME/dotfiles/zsh/prompt.zsh" ]; then
    . "$HOME/dotfiles/zsh/prompt.zsh"
fi

# Initialize Oh My Zsh (this was missing!)
source $ZSH/oh-my-zsh.sh

# Load functions that are shared across shells
if [ -f "$HOME/dotfiles/.shell_functions.sh" ]; then
    . "$HOME/dotfiles/.shell_functions.sh"
fi

# Set up SSH agent bridge in WSL2
# SSH agent setup (uncomment to enable)
if [ -f "$HOME/dotfiles/zsh/ssh-agent.zsh" ]; then
    . "$HOME/dotfiles/zsh/ssh-agent.zsh"
fi

# Always set basic shell settings since we're lazy loading Oh My Zsh
autoload -U compinit && compinit
setopt CORRECT
setopt EXTENDED_GLOB
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Enhanced history search for the history-substring-search plugin
if [[ -n "${plugins[(r)history-substring-search]}" ]]; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# Preferred editor per context
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='code'
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
