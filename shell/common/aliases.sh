#!/bin/bash
# Common aliases for all shells and platforms
# Part of the modular dotfiles configuration system

# Navigation aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Directory aliases
alias dotfiles='cd $DOTFILES_ROOT'
alias projects='cd $PROJECTS_ROOT'
alias home='cd ~'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Utility aliases
alias h='history'
alias c='clear'
alias e='exit'
alias reload='source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null'

# Platform-specific aliases will be loaded from platform-specific modules
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS specific aliases
    alias finder='open -a Finder'
    alias preview='open -a Preview'
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux specific aliases
    alias open='xdg-open'
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows/Git Bash specific aliases
    alias explorer='explorer.exe'
fi

# Development aliases
alias py='python3'
alias pip='pip3'
alias npm-global='npm list -g --depth=0'
alias serve='python3 -m http.server'

# Docker aliases (if docker is available)
if command -v docker &> /dev/null; then
    alias dk='docker'
    alias dc='docker-compose'
    alias dps='docker ps'
    alias di='docker images'
fi

# VS Code aliases (if code is available)
if command -v code &> /dev/null; then
    alias code.='code .'
    alias codei='code --install-extension'
fi
