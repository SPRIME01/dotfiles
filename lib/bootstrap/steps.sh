#!/usr/bin/env bash
# Description: Modular bootstrap step functions extracted from bootstrap.sh
# Category: library
# Dependencies: bash
# Idempotent: yes (each function guarded)
set -euo pipefail

bootstrap_link_shell_configs() {
	local root="$1"
	ln -sf "$root/.bashrc" ~/.bashrc
	ln -sf "$root/.zshrc" ~/.zshrc
	ln -sf "$root/.shell_common.sh" ~/.shell_common
	ln -sf "$root/.shell_theme_common.ps1" ~/.shell_theme_common
	ln -sf "$root/.shell_functions.sh" ~/.shell_functions
	echo "✅ Shell config symlinks updated"
}

bootstrap_install_oh_my_posh() {
	local root="$1"
	if [ -f "$root/scripts/install-oh-my-posh.sh" ]; then
		bash "$root/scripts/install-oh-my-posh.sh" || echo "⚠️  oh-my-posh installer reported a non-zero exit; continuing"
	else
		echo "⚠️  install-oh-my-posh.sh missing; skipping"
	fi
}

bootstrap_install_oh_my_zsh() {
	if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
		if command -v curl >/dev/null 2>&1; then
			echo "📦 Installing Oh My Zsh..."
			sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
		else
			echo "⚠️ curl not available; skipping Oh My Zsh installation"
		fi
	else
		echo "✅ Oh My Zsh already installed"
	fi
}

bootstrap_zsh_linux_setup() {
	local root="$1"
	if is_linux || is_wsl; then
		if [ -f "$root/install_zsh.sh" ]; then
			chmod +x "$root/install_zsh.sh"
			"$root/install_zsh.sh" || true
		fi
	fi
}

bootstrap_mcp() {
	local root="$1"
	echo "🔧 Setting up MCP configuration..."
	if [ -d "$root/mcp" ]; then
		echo "✅ MCP directory present"
	else
		echo "⚠️  MCP directory missing"
	fi
}

bootstrap_vscode() {
	local root="$1"
	echo "💻 Setting up VS Code configuration..."
	if [ -f "$root/install/vscode.sh" ]; then
		"$root/install/vscode.sh" || echo "⚠️  VS Code installation script reported a non-zero exit; continuing"
	else
		echo "⚠️  VS Code installation script not found"
	fi
}

bootstrap_doctor() {
	local root="$1"
	echo "🩺 Running doctor checks..."
	if [ -x "$root/scripts/doctor.sh" ]; then
		DOTFILES_ROOT="$root" bash "$root/scripts/doctor.sh" || true
	else
		echo "(doctor script unavailable)"
	fi
}
