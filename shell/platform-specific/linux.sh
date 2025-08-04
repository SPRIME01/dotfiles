#!/bin/bash
# Linux-specific configuration
# Part of the modular dotfiles configuration system

# Linux-specific environment variables
export BROWSER="${BROWSER:-firefox}"

# Linux-specific aliases
alias open='xdg-open'
alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
alias ll='ls -alF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Package manager aliases based on distribution
if command -v apt &> /dev/null; then
    # Debian/Ubuntu
    alias install='sudo apt install'
    alias update='sudo apt update && sudo apt upgrade'
    alias search='apt search'
    alias remove='sudo apt remove'
    alias autoremove='sudo apt autoremove'
elif command -v dnf &> /dev/null; then
    # Fedora
    alias install='sudo dnf install'
    alias update='sudo dnf update'
    alias search='dnf search'
    alias remove='sudo dnf remove'
    alias autoremove='sudo dnf autoremove'
elif command -v yum &> /dev/null; then
    # RHEL/CentOS
    alias install='sudo yum install'
    alias update='sudo yum update'
    alias search='yum search'
    alias remove='sudo yum remove'
elif command -v pacman &> /dev/null; then
    # Arch Linux
    alias install='sudo pacman -S'
    alias update='sudo pacman -Syu'
    alias search='pacman -Ss'
    alias remove='sudo pacman -R'
elif command -v zypper &> /dev/null; then
    # openSUSE
    alias install='sudo zypper install'
    alias update='sudo zypper update'
    alias search='zypper search'
    alias remove='sudo zypper remove'
fi

# Linux-specific functions
systemctl_status() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: systemctl_status <service_name>"
        return 1
    fi
    sudo systemctl status "$1"
}

systemctl_restart() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: systemctl_restart <service_name>"
        return 1
    fi
    sudo systemctl restart "$1"
}

# Memory and disk usage
meminfo() {
    free -h
}

diskinfo() {
    df -h
}

# Network utilities
netstat_listening() {
    netstat -tuln
}

# Process tree
pstree_user() {
    pstree -p "$USER"
}

# Find large files
find_large_files() {
    local size="${1:-100M}"
    find / -type f -size +"$size" 2>/dev/null | head -20
}

# Linux-specific path additions
if [[ -d "/usr/local/bin" ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

if [[ -d "/snap/bin" ]]; then
    export PATH="/snap/bin:$PATH"
fi

# WSL-specific configuration
if grep -qi microsoft /proc/version 2>/dev/null; then
    # We're in WSL
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0

    # WSL-specific aliases
    alias windows='cd /mnt/c/Users'
    alias wsl-shutdown='wsl.exe --shutdown'

    # Windows path integration (be careful with this)
    if [[ -d "/mnt/c/Windows/System32" ]]; then
        export PATH="$PATH:/mnt/c/Windows/System32"
    fi
fi
