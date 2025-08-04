#!/bin/bash
# macOS-specific configuration
# Part of the modular dotfiles configuration system

# macOS-specific environment variables
export BROWSER="${BROWSER:-open}"

# macOS-specific aliases
alias finder='open -a Finder'
alias preview='open -a Preview'
alias textedit='open -a TextEdit'
alias safari='open -a Safari'
alias chrome='open -a "Google Chrome"'
alias firefox='open -a Firefox'

# BSD ls (macOS default)
alias ll='ls -alF'
alias ls='ls -G'
alias la='ls -la'

# Homebrew aliases
if command -v brew &> /dev/null; then
    alias install='brew install'
    alias cask-install='brew install --cask'
    alias update='brew update && brew upgrade'
    alias search='brew search'
    alias remove='brew uninstall'
    alias cleanup='brew cleanup'
    alias doctor='brew doctor'
    alias services='brew services list'
fi

# macOS-specific functions
# Show/hide hidden files in Finder
show_hidden() {
    defaults write com.apple.finder AppleShowAllFiles YES
    killall Finder
}

hide_hidden() {
    defaults write com.apple.finder AppleShowAllFiles NO
    killall Finder
}

# Empty trash
empty_trash() {
    sudo rm -rf ~/.Trash/*
}

# Get macOS version
macos_version() {
    sw_vers
}

# Network utilities for macOS
flush_dns() {
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
}

# QuickLook a file
ql() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: ql <file>"
        return 1
    fi
    qlmanage -p "$1" &> /dev/null
}

# Copy current directory path to clipboard
pwd_copy() {
    pwd | pbcopy
    echo "Current directory path copied to clipboard"
}

# Screenshot functions
screenshot() {
    local filename="screenshot_$(date +%Y%m%d_%H%M%S).png"
    screencapture -x "$HOME/Desktop/$filename"
    echo "Screenshot saved to ~/Desktop/$filename"
}

screenshot_selection() {
    local filename="screenshot_$(date +%Y%m%d_%H%M%S).png"
    screencapture -s "$HOME/Desktop/$filename"
    echo "Screenshot saved to ~/Desktop/$filename"
}

# Xcode utilities (if Xcode is installed)
if command -v xcodebuild &> /dev/null; then
    alias xcode='open -a Xcode'
    alias simulator='open -a Simulator'

    clean_derived_data() {
        rm -rf ~/Library/Developer/Xcode/DerivedData/*
        echo "Cleaned Xcode derived data"
    }
fi

# macOS-specific path additions
if [[ -d "/usr/local/bin" ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

if [[ -d "/opt/homebrew/bin" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

if [[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]]; then
    export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
fi

# Homebrew environment
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
