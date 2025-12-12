# Zsh Enhancements - Quality of Life Improvements
# This file contains history settings, completion improvements, key bindings, and tool integrations

# ============================================================================
# History Configuration
# ============================================================================

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

# History options
setopt EXTENDED_HISTORY          # Write timestamp to history file
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Don't record duplicate commands
setopt HIST_IGNORE_SPACE         # Ignore commands starting with space
setopt HIST_VERIFY               # Show command with history expansion
setopt SHARE_HISTORY             # Share history between sessions
setopt INC_APPEND_HISTORY        # Write to history immediately

# ============================================================================
# Completion Enhancements
# ============================================================================

# Better completion
zstyle ':completion:*' menu select                        # Interactive menu
zstyle ':completion:*' rehash true                        # Auto rehash commands
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # Colored completions
zstyle ':completion:*' special-dirs true                  # Complete . and ..
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"  # Better process completion

# Better completion for kill command
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# ============================================================================
# Key Bindings
# ============================================================================

# Better key bindings (emacs-style)
bindkey '^[[A' history-substring-search-up      # Up arrow
bindkey '^[[B' history-substring-search-down    # Down arrow
bindkey '^[[H' beginning-of-line                # Home
bindkey '^[[F' end-of-line                      # End
bindkey '^[[3~' delete-char                     # Delete
bindkey '^[[1;5C' forward-word                  # Ctrl+Right
bindkey '^[[1;5D' backward-word                 # Ctrl+Left

# ============================================================================
# Tool Integrations
# ============================================================================

# fzf - Fuzzy Finder
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
    
    # Better fzf defaults
    export FZF_DEFAULT_OPTS="
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=dark
        --color=fg:-1,bg:-1,hl:#5fff87,fg+:-1,bg+:-1,hl+:#ffaf5f
        --color=info:#af87ff,prompt:#5fff87,pointer:#ff87d7,marker:#ff87d7,spinner:#ff87d7
    "
    
    # Use fd if available for better performance
    if command -v fd > /dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# zoxide - Smart directory jumping
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    
    # Alias z to cd for muscle memory
    alias cd='z'
fi

# ============================================================================
# Enhanced Aliases
# ============================================================================

# Modern ls replacement (eza)
if command -v eza > /dev/null 2>&1; then
    alias ls='eza --icons'
    alias ll='eza -l --icons --git'
    alias la='eza -la --icons --git'
    alias lt='eza --tree --level=2 --icons'
    alias llt='eza -l --tree --level=2 --icons --git'
else
    # Fallback to traditional ls with colors
    alias ls='ls --color=auto'
    alias ll='ls -lh'
    alias la='ls -lah'
fi

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git shortcuts (complementing Oh My Zsh git plugin)
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gdc='git diff --cached'
alias glog='git log --oneline --graph --decorate --all'
alias gp='git pull'
alias gpu='git push'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git checkout -b'

# Docker shortcuts (complementing custom functions)
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'

# Productivity aliases
alias h='history | grep'
alias ports='netstat -tulanp'
alias mkdir='mkdir -pv'
alias wget='wget -c'  # Resume downloads by default
alias df='df -h'      # Human-readable sizes
alias du='du -h'      # Human-readable sizes
alias free='free -h'  # Human-readable sizes

# Quick file operations
alias cp='cp -iv'     # Interactive, verbose
alias mv='mv -iv'     # Interactive, verbose
alias rm='rm -v'      # Verbose (not interactive to avoid annoyance)

# ============================================================================
# Additional Options
# ============================================================================

# Auto-cd: just type directory name to cd into it
setopt AUTO_CD

# Pushd options
setopt AUTO_PUSHD           # Make cd push old dir onto dir stack
setopt PUSHD_IGNORE_DUPS   # Don't push duplicates
setopt PUSHD_SILENT        # Don't print dir stack after pushd/popd

# Globbing options
setopt EXTENDED_GLOB       # Use extended globbing syntax

# ============================================================================
# Zsh Performance Optimizations
# ============================================================================

# Skip global compinit (Oh My Zsh does this)
skip_global_compinit=1

# Disable oh-my-zsh automatic updates (manual control)
zstyle ':omz:update' mode disabled
