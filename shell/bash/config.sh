#!/bin/bash
# Bash-specific configuration
# Part of the modular dotfiles configuration system

# Bash-specific history settings
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"
export HISTTIMEFORMAT='%F %T '

# Bash-specific options
shopt -s histappend        # Append to history file, don't overwrite
shopt -s checkwinsize      # Check window size after each command
shopt -s cdspell           # Correct minor spelling errors in cd
shopt -s dirspell          # Correct minor spelling errors in directory names
shopt -s nocaseglob        # Case-insensitive filename matching
shopt -s autocd 2>/dev/null # Auto-cd into directories (bash 4.0+)

# Bash completion
if [[ -f /etc/bash_completion ]]; then
    source /etc/bash_completion
elif [[ -f /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -f /usr/local/etc/bash_completion ]]; then
    # macOS with Homebrew
    source /usr/local/etc/bash_completion
fi

# Git completion (if available)
if [[ -f /usr/share/bash-completion/completions/git ]]; then
    source /usr/share/bash-completion/completions/git
elif [[ -f /usr/local/etc/bash_completion.d/git-completion.bash ]]; then
    source /usr/local/etc/bash_completion.d/git-completion.bash
fi

# Bash-specific functions
bash_reload() {
    if [[ -f ~/.bashrc ]]; then
        source ~/.bashrc
        echo "Bash configuration reloaded"
    else
        echo "~/.bashrc not found"
    fi
}

# Bash prompt customization (basic)
# Note: More advanced prompts should be configured in the main bash configuration
if [[ -z "$PS1" ]]; then
    # We're in a non-interactive shell, don't set prompt
    :
elif [[ "$TERM" == "dumb" ]]; then
    # Simple prompt for dumb terminals
    PS1='$ '
else
    # Basic colored prompt
    if [[ "$EUID" -eq 0 ]]; then
        # Root user - red prompt
        PS1='\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# '
    else
        # Regular user - green prompt
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '
    fi
fi

# Bash-specific key bindings (only in interactive mode)
if [[ $- == *i* ]]; then
    bind '"\e[A": history-search-backward'  # Up arrow
    bind '"\e[B": history-search-forward'   # Down arrow
    bind '"\e[5~": beginning-of-history'    # Page up
    bind '"\e[6~": end-of-history'          # Page down
fi

# Bash-specific aliases
alias bashrc='$EDITOR ~/.bashrc'
alias rebash='bash_reload'
