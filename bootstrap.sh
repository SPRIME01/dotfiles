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
ln -sf "$DOTFILES/.shell_functions.sh" ~/.shell_functions

# Install oh-my-posh if not present (skip when NO_NETWORK=1)
if [[ "${NO_NETWORK:-0}" != "1" ]]; then
	if ! command -v oh-my-posh &>/dev/null; then
		echo "📦 Installing oh-my-posh..."
		curl -s https://ohmyposh.dev/install.sh | bash -s
	fi
else
	echo "ℹ️  NO_NETWORK=1 set; skipping oh-my-posh installation"
fi

# Install Oh My Zsh for Linux/WSL2 environments
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
	echo "🐧 Detected Linux/WSL2 environment"

	# Make install_zsh.sh executable and run it (skip when NO_NETWORK=1)
	if [[ "${NO_NETWORK:-0}" == "1" ]]; then
		echo "ℹ️  NO_NETWORK=1 set; skipping Oh My Zsh installation"
	else
		if [ -f "$DOTFILES/install_zsh.sh" ]; then
			chmod +x "$DOTFILES/install_zsh.sh"
			echo "🐚 Installing Oh My Zsh..."
			"$DOTFILES/install_zsh.sh"
		else
			echo "⚠️  install_zsh.sh not found, skipping Zsh setup"
		fi
	fi
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
if [[ "${NO_NETWORK:-0}" != "1" ]]; then
	if [ -f "$DOTFILES/install/vscode.sh" ]; then
		echo "🔧 Installing VS Code settings..."
		"$DOTFILES/install/vscode.sh"
	else
		echo "⚠️  VS Code installation script not found"
	fi
else
	echo "ℹ️  NO_NETWORK=1 set; skipping VS Code settings installation"
fi

echo "🎉 Bootstrap complete!"
echo "💡 To use MCP helper tools, run:"
echo "   $DOTFILES/mcp/mcp-helper.sh env      # Show MCP environment"
echo "   $DOTFILES/mcp/mcp-helper.ps1 env     # Show MCP environment (PowerShell)"
