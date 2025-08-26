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

# Install oh-my-posh if not present
if ! command -v oh-my-posh &>/dev/null; then
	echo "📦 Installing oh-my-posh..."
	curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# Ensure Oh My Zsh is installed (idempotent, unattended)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
	echo "📦 Installing Oh My Zsh..."
	if command -v curl >/dev/null 2>&1; then
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
	else
		echo "⚠️ curl not available; skipping Oh My Zsh installation"
	fi
else
	echo "✅ Oh My Zsh already installed"
fi

# Install Oh My Zsh for Linux/WSL2 environments
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
	echo "🐧 Detected Linux/WSL2 environment"

	# Make install_zsh.sh executable and run it
	if [ -f "$DOTFILES/install_zsh.sh" ]; then
		chmod +x "$DOTFILES/install_zsh.sh"
		echo "🐚 Installing Oh My Zsh..."
		"$DOTFILES/install_zsh.sh"
	else
		echo "⚠️  install_zsh.sh not found, skipping Zsh setup"
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

echo
echo "🩺 Running dotfiles doctor (optional health checks)..."
if [ -x "$DOTFILES/scripts/doctor.sh" ]; then
	DOTFILES_ROOT="$DOTFILES" bash "$DOTFILES/scripts/doctor.sh" || true
else
	echo "(doctor not found)"
fi
