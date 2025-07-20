#!/bin/bash
# dotfiles/install_complete.sh
# Complete installation script for all shell environments
# Version: 1.0
# Last Modified: July 20, 2025

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting complete dotfiles installation..."
echo "📁 Dotfiles directory: $DOTFILES"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS and environment
detect_environment() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WINDIR" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS_TYPE=$(detect_environment)
echo "🖥️  Detected environment: $OS_TYPE"

# Create symlinks for shell configuration files
echo "🔗 Creating symlinks for shell configuration files..."
ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES/.shell_functions.sh" ~/.shell_functions
ln -sf "$DOTFILES/.shell_theme_common.ps1" ~/.shell_theme_common

# Create symlink for Powerlevel10k config if it doesn't exist
if [ ! -f ~/.p10k.zsh ]; then
    ln -sf "$DOTFILES/.p10k.zsh" ~/.p10k.zsh
fi

echo "✅ Shell configuration symlinks created"

# Install Oh My Posh (cross-platform)
if ! command_exists oh-my-posh; then
    echo "📦 Installing Oh My Posh..."
    if [[ "$OS_TYPE" == "linux" ]]; then
        curl -s https://ohmyposh.dev/install.sh | bash -s
    elif [[ "$OS_TYPE" == "windows" ]]; then
        # For Windows, suggest manual installation or use winget
        echo "⚠️  For Windows, please install Oh My Posh manually:"
        echo "   winget install JanDeDobbeleer.OhMyPosh -s winget"
        echo "   or visit: https://ohmyposh.dev/docs/installation/windows"
    fi
else
    echo "✅ Oh My Posh already installed"
fi

# Linux/WSL2 specific setup
if [[ "$OS_TYPE" == "linux" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo "🐧 Setting up Linux/WSL2 environment..."

    # Install Zsh if not present
    if ! command_exists zsh; then
        echo "📦 Installing Zsh..."
        if command_exists apt; then
            sudo apt update && sudo apt install -y zsh curl git
        elif command_exists yum; then
            sudo yum install -y zsh curl git
        elif command_exists dnf; then
            sudo dnf install -y zsh curl git
        elif command_exists pacman; then
            sudo pacman -S zsh curl git
        else
            echo "❌ Could not detect package manager. Please install zsh manually."
        fi
    fi

    # Run Zsh setup
    if [ -f "$DOTFILES/install_zsh.sh" ]; then
        chmod +x "$DOTFILES/install_zsh.sh"
        echo "🐚 Installing Oh My Zsh..."
        "$DOTFILES/install_zsh.sh"
    else
        echo "⚠️  install_zsh.sh not found, skipping Zsh setup"
    fi
fi

# PowerShell setup (if PowerShell is available)
if command_exists pwsh || command_exists powershell; then
    echo "💜 PowerShell detected, setting up PowerShell environment..."

    # Determine PowerShell command
    PS_CMD=""
    if command_exists pwsh; then
        PS_CMD="pwsh"
    elif command_exists powershell; then
        PS_CMD="powershell"
    fi

    if [ -f "$DOTFILES/bootstrap.ps1" ]; then
        echo "🔧 Running PowerShell bootstrap..."
        $PS_CMD -ExecutionPolicy Bypass -File "$DOTFILES/bootstrap.ps1"
    else
        echo "⚠️  PowerShell bootstrap script not found"
    fi
else
    echo "ℹ️  PowerShell not found, skipping PowerShell setup"
fi

# Setup MCP configuration
echo "🔧 Setting up MCP (Model Context Protocol) configuration..."
if [ ! -d "$DOTFILES/mcp" ]; then
    echo "⚠️  MCP directory not found. Run 'git pull' to get latest dotfiles."
else
    echo "✅ MCP configuration directory found"
    if [ -f "$DOTFILES/mcp/.env" ]; then
        echo "✅ MCP environment file found"
    else
        echo "⚠️  MCP environment file not found. You may need to configure MCP manually."
    fi
fi

# Setup VS Code configuration
echo "💻 Setting up VS Code configuration..."
if [ -f "$DOTFILES/install/vscode.sh" ]; then
    echo "🔧 Installing VS Code settings..."
    chmod +x "$DOTFILES/install/vscode.sh"
    "$DOTFILES/install/vscode.sh"
else
    echo "⚠️  VS Code installation script not found"
fi

# Final instructions
echo ""
echo "🎉 Complete dotfiles installation finished!"
echo ""
echo "📋 Next Steps:"

if [[ "$OS_TYPE" == "linux" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo "   🐚 For Zsh:"
    echo "      1. Restart your terminal or run 'exec zsh'"
    echo "      2. Run 'p10k configure' to configure Powerlevel10k theme"
    echo "      3. Set terminal font to 'MesloLGS NF' for best experience"
fi

if command_exists pwsh || command_exists powershell; then
    echo "   💜 For PowerShell:"
    echo "      1. Restart PowerShell"
    echo "      2. Run 'updatealiases' to generate custom aliases"
    echo "      3. Type 'aliashelp' to see available commands"
fi

echo ""
echo "💡 Useful commands:"
echo "   - 'sysinfo' - System information"
echo "   - 'projects' - List all projects"
echo "   - 'mcpstatus' - MCP configuration status"
echo "   - 'note \"your note\"' - Quick note taking"
echo ""
echo "🔧 MCP helper tools:"
echo "   $DOTFILES/mcp/mcp-helper.sh env      # Show MCP environment (bash/zsh)"
echo "   $DOTFILES/mcp/mcp-helper.ps1 env     # Show MCP environment (PowerShell)"
