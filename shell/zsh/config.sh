#!/bin/zsh
# Zsh-specific configuration
# Part of the modular dotfiles configuration system

# Zsh-specific history settings
export HISTSIZE=50000
export SAVEHIST=50000
export HISTFILE=~/.zsh_history

# Zsh history options
setopt EXTENDED_HISTORY          # Write timestamps to history file
setopt SHARE_HISTORY            # Share history between sessions
setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicate entries first
setopt HIST_IGNORE_DUPS         # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS     # Delete old duplicate entries
setopt HIST_FIND_NO_DUPS        # Don't display duplicates in search
setopt HIST_IGNORE_SPACE        # Don't record entries starting with space
setopt HIST_SAVE_NO_DUPS        # Don't write duplicates to history file
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks
setopt HIST_VERIFY              # Show command with history expansion before running

# Zsh options
setopt AUTO_CD                  # Auto-cd into directories
setopt AUTO_PUSHD               # Automatically push directories onto stack
setopt PUSHD_IGNORE_DUPS        # Don't duplicate directories in stack
setopt PUSHD_MINUS              # Exchange meaning of + and - for stack
setopt CORRECT                  # Try to correct spelling of commands
setopt CORRECT_ALL              # Try to correct spelling of all arguments
setopt NO_CASE_GLOB             # Case-insensitive globbing
setopt EXTENDED_GLOB            # Enable extended globbing patterns
setopt GLOB_DOTS                # Don't require leading '.' in filename to be matched
setopt NUMERIC_GLOB_SORT        # Sort numeric filenames numerically
setopt COMPLETE_IN_WORD         # Complete from both ends of word
setopt AUTO_MENU                # Use menu completion after second tab
setopt AUTO_LIST                # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH         # Add trailing slash to directory names
setopt FLOW_CONTROL             # Disable start/stop characters (ctrl-s/ctrl-q)

# Zsh completion system
autoload -Uz compinit
compinit

# Completion options
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose true

# Git completion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

# Zsh-specific functions
zsh_reload() {
    if [[ -f ~/.zshrc ]]; then
        source ~/.zshrc
        echo "Zsh configuration reloaded"
    else
        echo "~/.zshrc not found"
    fi
}

# Directory stack functions
dirsv() {
    if [[ -n $1 ]]; then
        dirs "$@"
    else
        dirs -v | head -20
    fi
}

# Quick directory navigation (functions cannot start with a number in zsh)
cd1() { cd -1 }
cd2() { cd -2 }
cd3() { cd -3 }
cd4() { cd -4 }
cd5() { cd -5 }

# Backward-compatible numeric aliases
alias 1='cd1'
alias 2='cd2'
alias 3='cd3'
alias 4='cd4'
alias 5='cd5'

# Zsh-specific key bindings
bindkey '^[[A' history-substring-search-up      # Up arrow
bindkey '^[[B' history-substring-search-down    # Down arrow
bindkey '^R' history-incremental-search-backward # Ctrl+R
bindkey '^S' history-incremental-search-forward  # Ctrl+S
bindkey '^[[1;5C' forward-word                   # Ctrl+Right
bindkey '^[[1;5D' backward-word                  # Ctrl+Left
bindkey '^[[3~' delete-char                      # Delete key
bindkey '^[[H' beginning-of-line                 # Home key
bindkey '^[[F' end-of-line                       # End key

# Zsh-specific aliases
alias zshrc='$EDITOR ~/.zshrc'
alias rezsh='zsh_reload'
alias dirs='dirs -v'

# Load zsh plugins if available
ZSH_PLUGINS_DIR="${ZSH_PLUGINS_DIR:-$HOME/.zsh/plugins}"

# Syntax highlighting
if [[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# History substring search
if [[ -f "$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi

# Autosuggestions
if [[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi
