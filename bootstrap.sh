#!/usr/bin/env bash
set -e

# Automatically determine the dotfiles directory based on where this script lives
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DOTFILES:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

echo "⚙️ Setting up Unix shell..."

DOTFILES=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Export DOTFILES_ROOT for state-management helpers (falls back to $HOME/dotfiles inside the library)
export DOTFILES_ROOT="$DOTFILES"

# Source state management helpers if available so bootstrap can record completion cleanly
if [[ -f "$DOTFILES/lib/state-management.sh" ]]; then
	# shellcheck disable=SC1090
	. "$DOTFILES/lib/state-management.sh"
fi

# Create symlinks for shell configuration files
ln -sf "$DOTFILES/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/.inputrc" ~/.inputrc
ln -sf "$DOTFILES/.shell_common.sh" ~/.shell_common
ln -sf "$DOTFILES/.shell_theme_common.ps1" ~/.shell_theme_common
ln -sf "$DOTFILES/.shell_functions.sh" ~/.shell_functions

# Install oh-my-posh if not present (skip when NO_NETWORK=1)
if [[ "${NO_NETWORK:-0}" != "1" ]]; then
	if ! command -v oh-my-posh &>/dev/null; then
		echo "📦 Installing oh-my-posh..."

		# Source secure installer and constants
		# shellcheck disable=SC1091
		source "$DOTFILES/lib/constants.sh"
		# shellcheck disable=SC1091
		source "$DOTFILES/lib/secure-install.sh"

		# Use secure installer with checksum verification
		secure_install "$OMP_INSTALLER_URL" "$OMP_INSTALLER_SHA256"
	fi
else
	echo "ℹ️  NO_NETWORK=1 set; skipping oh-my-posh installation"
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
if type write_state_key >/dev/null 2>&1; then
	# Record a single timestamp for the last successful bootstrap run.
	write_state_key "setup_completed" "$(date -Iseconds)"
fi
echo "💡 To use MCP helper tools, run:"
echo "   $DOTFILES/mcp/mcp-helper.sh env      # Show MCP environment"
echo "   $DOTFILES/mcp/mcp-helper.ps1 env     # Show MCP environment (PowerShell)"
