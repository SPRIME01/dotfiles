#!/bin/bash
# Windows/Git Bash/MSYS specific configuration
# Part of the modular dotfiles configuration system

# Windows-specific environment variables
export BROWSER="${BROWSER:-start}"

# Windows-specific aliases
alias explorer='explorer.exe'
alias notepad='notepad.exe'
alias cmd='cmd.exe'
alias powershell='powershell.exe'
alias pwsh='pwsh.exe'

# Windows-specific ls behavior
alias ll='ls -alF'
alias la='ls -la'

# Windows package managers
if command -v winget &> /dev/null; then
    alias install='winget install'
    alias search='winget search'
    alias update='winget upgrade --all'
fi

if command -v choco &> /dev/null; then
    alias choco-install='choco install'
    alias choco-update='choco upgrade all'
    alias choco-search='choco search'
fi

if command -v scoop &> /dev/null; then
    alias scoop-install='scoop install'
    alias scoop-update='scoop update *'
    alias scoop-search='scoop search'
fi

# Windows-specific functions
# Open current directory in Windows Explorer
explore() {
    local path="${1:-.}"
    explorer.exe "$(wslpath -w "$path" 2>/dev/null || echo "$path")"
}

# Convert WSL path to Windows path
winpath() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: winpath <linux_path>"
        return 1
    fi
    wslpath -w "$1" 2>/dev/null || echo "$1"
}

# Convert Windows path to WSL path
linuxpath() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: linuxpath <windows_path>"
        return 1
    fi
    wslpath "$1" 2>/dev/null || echo "$1"
}

# Windows network utilities
ipconfig() {
    ipconfig.exe "$@"
}

ping() {
    ping.exe "$@"
}

# Windows system info
sysinfo() {
    systeminfo.exe
}

# Windows service management
service_list() {
    sc.exe query type= service state= all
}

service_status() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: service_status <service_name>"
        return 1
    fi
    sc.exe query "$1"
}

# Windows-specific path additions
if [[ -d "/c/Windows/System32" ]]; then
    export PATH="$PATH:/c/Windows/System32"
fi

if [[ -d "/c/Program Files/Git/bin" ]]; then
    export PATH="$PATH:/c/Program Files/Git/bin"
fi

# Visual Studio Code (Windows)
if [[ -d "/c/Program Files/Microsoft VS Code/bin" ]]; then
    export PATH="$PATH:/c/Program Files/Microsoft VS Code/bin"
fi

# Node.js (Windows)
if [[ -d "/c/Program Files/nodejs" ]]; then
    export PATH="$PATH:/c/Program Files/nodejs"
fi

# Python (Windows)
if [[ -d "/c/Python39" ]]; then
    export PATH="$PATH:/c/Python39"
    export PATH="$PATH:/c/Python39/Scripts"
fi

# Windows-specific environment variables
export WINHOME="/c/Users/$USER"

# Fix for Windows line endings in Git Bash
if command -v git &> /dev/null; then
    alias git='git --config core.autocrlf=true'
fi
