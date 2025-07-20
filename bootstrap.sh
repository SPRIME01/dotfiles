#!/usr/bin/env bash
set -e

# Automatically determine the dotfiles directory based on where this script lives
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo "⚙️ Setting up Unix shell..."

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Create symlinks for shell configuration files
ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES/.shell_theme_common.ps1" ~/.shell_theme_common

# Install oh-my-posh if not present
if ! command -v oh-my-posh &> /dev/null; then
    echo "📦 Installing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
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
    "$DOTFILES/install/vscode.sh"
else
    echo "⚠️  VS Code installation script not found"
fi

echo "🎉 Bootstrap complete!"
echo "💡 To use MCP helper tools, run:"
echo "   $DOTFILES/mcp/mcp-helper.sh env      # Show MCP environment"
echo "   $DOTFILES/mcp/mcp-helper.ps1 env     # Show MCP environment (PowerShell)"
