#!/usr/bin/env bash
# DEPRECATED / LEGACY: This variant is retained for reference only.
# The canonical and supported setup wizard is:
#   bash scripts/setup-wizard.sh
# If you previously used this script, please switch to the canonical script.
#
# Differences (summary):
# - Older prompting flow and ordering of component installs
# - Slightly different wording and batch-file fallbacks for Windows projects
# - The canonical script consolidates state helpers, more robust fallbacks,
#   and explicit non-interactive flags (--force/--interactive)
#
# This file remains in the repository only for historical comparison and
# debugging; do not rely on it for new automation or CI tasks.

set -euo pipefail

# Interactive setup wizard for the dotfiles project with idempotent state management.
# This improved version tracks installation state to avoid redundant operations
# and provides intelligent prompting based on previous installation attempts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load state management functions
source "$DOTFILES_ROOT/lib/state-management.sh"

echo "📦 Welcome to the dotfiles setup wizard!"
echo "This wizard will help you configure your development environment."
echo

# Show current installation status if any setup has been done
if has_any_setup_been_done; then
	echo "📋 Current installation status:"
	show_installation_status
	echo

	# Check for failed components and offer to retry
	failed_components=$(get_failed_components)
	if [[ -n "$failed_components" ]]; then
		echo "⚠️  Some components failed in previous runs:"
		echo "$failed_components"
		echo
		if prompt_yes_no "Would you like to retry failed components only?" "n"; then
			RETRY_FAILED_ONLY=true
		else
			RETRY_FAILED_ONLY=false
		fi
	else
		RETRY_FAILED_ONLY=false
	fi

	if prompt_yes_no "Would you like to force reinstall all components?" "n"; then
		FORCE_REINSTALL=true
		RETRY_FAILED_ONLY=false
	else
		FORCE_REINSTALL=false
	fi
else
	echo "🚀 This appears to be your first time running the setup wizard."
	RETRY_FAILED_ONLY=false
	FORCE_REINSTALL=false
fi

# Helper to prompt with default value
prompt_yes_no() {
	local prompt="$1"
	local default="$2"
	local reply
	if [ "$default" = "y" ]; then
		prompt="$prompt [Y/n] "
	else
		prompt="$prompt [y/N] "
	fi
	read -r -p "$prompt" reply
	reply="${reply:-$default}"
	if [[ "$reply" =~ ^[Yy]$ ]]; then
		return 0
	fi
	return 1
}

# Safe execution wrapper
safe_execute() {
	local component="$1"
	local description="$2"
	local command="$3"

	echo "▶️  $description..."
	if eval "$command"; then
		mark_component_installed "$component"
		echo "✅ $description completed successfully"
		return 0
	else
		mark_component_failed "$component" "$description failed"
		echo "❌ $description failed"
		return 1
	fi
}

# Determine available shells
available_pwsh=0
if command -v pwsh >/dev/null 2>&1; then
	available_pwsh=1
fi

# Initialize component flags
configure_bash=0
configure_zsh=0
configure_pwsh=0
install_vscode=0
enable_hook=0
enable_bridge=0
setup_projects=0
setup_pwsh7_windows=0
setup_ssh_agent_windows=0

# Determine what to install based on mode
if [[ "$RETRY_FAILED_ONLY" == "true" ]]; then
	echo "🔄 Retrying failed components only..."

	# Check each component and set flags based on failure status
	if grep -q "^bash_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		configure_bash=1
		echo "🔄 Will retry: Bash configuration"
	fi
	if grep -q "^zsh_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		configure_zsh=1
		echo "🔄 Will retry: Zsh configuration"
	fi
	if grep -q "^pwsh_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		configure_pwsh=1
		echo "🔄 Will retry: PowerShell configuration"
	fi
	if grep -q "^vscode_settings=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		install_vscode=1
		echo "🔄 Will retry: VS Code settings"
	fi
	if grep -q "^git_hook=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		enable_hook=1
		echo "🔄 Will retry: Git hooks"
	fi
	if grep -q "^ssh_bridge=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		enable_bridge=1
		echo "🔄 Will retry: SSH bridge"
	fi
	if grep -q "^projects_setup=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		setup_projects=1
		echo "🔄 Will retry: Projects setup"
	fi
	if grep -q "^pwsh7_windows=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		setup_pwsh7_windows=1
		echo "🔄 Will retry: PowerShell 7 Windows integration"
	fi
	if grep -q "^ssh_agent_windows=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
		setup_ssh_agent_windows=1
		echo "🔄 Will retry: Windows SSH Agent"
	fi
else
	# Interactive prompting with smart state checking
	echo "🤔 Let's determine what to install..."
	echo

	# Shell configuration
	if smart_prompt_yes_no "bash_config" "Do you want to configure Bash?" "y" "$FORCE_REINSTALL"; then
		configure_bash=1
	fi
	if smart_prompt_yes_no "zsh_config" "Do you want to configure Zsh?" "y" "$FORCE_REINSTALL"; then
		configure_zsh=1
	fi
	if [ "$available_pwsh" -eq 1 ]; then
		if smart_prompt_yes_no "pwsh_config" "Do you want to configure PowerShell?" "y" "$FORCE_REINSTALL"; then
			configure_pwsh=1
		fi
	else
		echo "⚠️  PowerShell (pwsh) is not installed; skipping PowerShell configuration."
		mark_component_skipped "pwsh_config" "PowerShell not available"
	fi

	# Additional components
	if smart_prompt_yes_no "vscode_settings" "Install VS Code settings from dotfiles?" "y" "$FORCE_REINSTALL"; then
		install_vscode=1
	fi

	if smart_prompt_yes_no "git_hook" "Install post-commit hook to auto-regenerate PowerShell aliases?" "y" "$FORCE_REINSTALL"; then
		enable_hook=1
	fi

	if smart_prompt_yes_no "ssh_bridge" "Enable WSL2 → Windows SSH agent bridge (WSL only)?" "y" "$FORCE_REINSTALL"; then
		enable_bridge=1
	fi

	if smart_prompt_yes_no "projects_setup" "Set up projects directory with Windows symlink (WSL2 only)?" "y" "$FORCE_REINSTALL"; then
		setup_projects=1
	fi

	# Platform-specific components
	if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
		if command -v pwsh.exe >/dev/null 2>&1; then
			if smart_prompt_yes_no "pwsh7_windows" "Set up PowerShell 7 profile for Windows integration?" "y" "$FORCE_REINSTALL"; then
				setup_pwsh7_windows=1
			fi
		else
			echo "ℹ️  PowerShell 7 (pwsh.exe) not detected on Windows; skipping Windows PowerShell 7 setup."
			mark_component_skipped "pwsh7_windows" "PowerShell 7 not available on Windows"
		fi

		if command -v powershell.exe >/dev/null 2>&1; then
			if smart_prompt_yes_no "ssh_agent_windows" "Set up Windows SSH Agent for automatic startup?" "y" "$FORCE_REINSTALL"; then
				setup_ssh_agent_windows=1
			fi
		else
			echo "ℹ️  PowerShell not detected on Windows; skipping SSH Agent setup."
			mark_component_skipped "ssh_agent_windows" "PowerShell not available on Windows"
		fi
	else
		mark_component_skipped "pwsh7_windows" "Not in WSL2 environment"
		mark_component_skipped "ssh_agent_windows" "Not in WSL2 environment"
	fi
fi

echo
echo "🔧 Applying your selections..."

# Track overall success
overall_success=true

# Configure Zsh (run first since it's most likely to succeed)
if [ "$configure_zsh" -eq 1 ]; then
	chmod +x "$DOTFILES_ROOT/install_zsh.sh" || true
	if ! safe_execute "zsh_config" "Installing Oh My Zsh and plugins" "bash '$DOTFILES_ROOT/install_zsh.sh'"; then
		overall_success=false
	fi
fi

# Configure Bash/general shell setup
if [ "$configure_bash" -eq 1 ] || [ "$configure_zsh" -eq 1 ]; then
	chmod +x "$DOTFILES_ROOT/bootstrap.sh" || true
	if ! safe_execute "bash_config" "Setting up shell symlinks and environment" "bash '$DOTFILES_ROOT/bootstrap.sh'"; then
		overall_success=false
	fi
fi

# Configure PowerShell
if [ "$configure_pwsh" -eq 1 ]; then
	if ! safe_execute "pwsh_config" "Setting up PowerShell configuration" "pwsh -NoProfile -ExecutionPolicy Bypass -File '$DOTFILES_ROOT/bootstrap.ps1'"; then
		overall_success=false
	fi
fi

# Install VS Code settings
if [ "$install_vscode" -eq 1 ]; then
	if [ -f "$DOTFILES_ROOT/install/vscode.sh" ]; then
		if ! safe_execute "vscode_settings" "Installing VS Code settings" "bash '$DOTFILES_ROOT/install/vscode.sh'"; then
			overall_success=false
		fi
	else
		echo "⚠️  VS Code installer script not found; skipping."
		mark_component_failed "vscode_settings" "installer script not found"
		overall_success=false
	fi
fi

# Install git hook with idempotent check
if [ "$enable_hook" -eq 1 ]; then
	HOOK_SRC="$DOTFILES_ROOT/scripts/git-hooks/post-commit"
	HOOK_DEST="$DOTFILES_ROOT/.git/hooks/post-commit"

	if [ -f "$HOOK_SRC" ]; then
		if [[ ! -f "$HOOK_DEST" ]] || [[ "$HOOK_SRC" -nt "$HOOK_DEST" ]]; then
			echo "▶️  Installing post-commit hook..."
			if mkdir -p "$DOTFILES_ROOT/.git/hooks" && cp "$HOOK_SRC" "$HOOK_DEST" && chmod +x "$HOOK_DEST"; then
				mark_component_installed "git_hook"
				echo "✅ Git hook installed successfully"
			else
				mark_component_failed "git_hook" "failed to install hook"
				overall_success=false
			fi
		else
			echo "✅ Git hook already up to date"
			mark_component_installed "git_hook"
		fi
	else
		echo "⚠️  Hook script not found at $HOOK_SRC; skipping."
		mark_component_failed "git_hook" "hook script not found"
		overall_success=false
	fi
fi

# SSH bridge setup (informational)
if [ "$enable_bridge" -eq 1 ]; then
	echo "ℹ️  SSH agent bridge will be configured in your shell startup files."
	echo "    Make sure npiperelay is installed: scoop install npiperelay"
	mark_component_installed "ssh_bridge"
fi

# Projects directory setup with improved idempotency
if [ "$setup_projects" -eq 1 ]; then
	echo "▶️  Setting up projects directory..."

	# Create projects directory (always safe)
	mkdir -p "$HOME/projects"
	echo "✅ Projects directory ensured at ~/projects"

	projects_success=true

	# Windows integration for WSL2
	if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
		WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
		if [[ -n "$WIN_USER" ]]; then
			WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"
			BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"

			# Check if symlink already exists
			if [[ -L "$WIN_PROJECTS_LINK" ]] && [[ -d "$WIN_PROJECTS_LINK" ]]; then
				echo "✅ Windows symlink already exists and is working"
			# Check if directory exists (but not symlink)
			elif [[ -d "$WIN_PROJECTS_LINK" ]]; then
				echo "ℹ️  Windows projects directory already exists (not a symlink)"
			else
				# Try to create the symlink
				WSL_PROJECTS_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
				echo "🔗 Creating Windows access to projects directory..."

				if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
					echo "✅ Windows symlink created at C:\\Users\\$WIN_USER\\projects"
				else
					echo "⚠️  Symlink requires admin privileges. Creating batch file fallback..."

					# Only create batch file if it doesn't exist or is outdated
					if [[ ! -f "$BATCH_FILE" ]]; then
						cat >"$BATCH_FILE" 2>/dev/null <<'EOF'
@echo off
REM Navigate to WSL2 projects directory
echo Opening WSL2 projects directory...
cd /d "\\wsl.localhost\%WSL_DISTRO_NAME%\home\%USERNAME%\projects"
if errorlevel 1 echo Error: Could not access WSL2 projects directory
cmd /k
EOF
						chmod +x "$BATCH_FILE" 2>/dev/null
						echo "✅ Created projects.bat at C:\\Users\\$WIN_USER\\projects.bat"
						echo "💡 Manual symlink command (run as Administrator):"
						echo "    mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\""
					else
						echo "✅ Batch file already exists at projects.bat"
					fi
				fi
			fi
		else
			echo "⚠️  Could not determine Windows username"
			projects_success=false
		fi
	fi

	if [ "$projects_success" = true ]; then
		mark_component_installed "projects_setup"
		echo "🎉 Projects setup complete!"
	else
		mark_component_failed "projects_setup" "Windows integration failed"
		overall_success=false
	fi
fi

# PowerShell 7 Windows setup
if [ "$setup_pwsh7_windows" -eq 1 ]; then
	if ! safe_execute "pwsh7_windows" "Setting up PowerShell 7 Windows integration" "bash '$DOTFILES_ROOT/scripts/setup-pwsh7.sh'"; then
		overall_success=false
	fi
fi

# Windows SSH Agent setup
if [ "$setup_ssh_agent_windows" -eq 1 ]; then
	if [[ -f "$DOTFILES_ROOT/scripts/setup-ssh-agent-windows-simple.ps1" ]]; then
		if ! safe_execute "ssh_agent_windows" "Setting up Windows SSH Agent" "powershell.exe -ExecutionPolicy Bypass -File '$DOTFILES_ROOT/scripts/setup-ssh-agent-windows-simple.ps1'"; then
			overall_success=false
		fi
	else
		echo "⚠️  SSH Agent setup script not found"
		mark_component_failed "ssh_agent_windows" "setup script not found"
		overall_success=false
	fi
fi

# Summary
echo
echo "=" x 50
if [ "$overall_success" = true ]; then
	echo "🎉 Setup completed successfully!"
	echo "✅ All selected components were installed without errors."
else
	echo "⚠️  Setup completed with some issues."
	echo "❌ Some components failed to install. Check the details above."
	echo "💡 You can run this wizard again to retry failed components."
fi

echo
echo "📋 Final installation status:"
show_installation_status

echo
echo "🚀 Next steps:"
echo "   • Restart your terminal or run: source ~/.zshrc"
echo "   • For Powerlevel10k theme: run 'p10k configure'"
echo "   • Check failed components and retry if needed"
echo "   • Review the documentation at docs/interface.md"

# Store final completion timestamp
echo "setup_completed=$(date -Iseconds)" >>"$DOTFILES_STATE_FILE"
