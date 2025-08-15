#!/usr/bin/env bash

# --- Determine Dotfiles Root ---
# Always derive DOTFILES_ROOT from the location of this file to ensure accuracy.
# This allows the repository to live anywhere on the filesystem and fixes issues
# where DOTFILES_ROOT might be incorrectly set from previous sessions.
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_ROOT

# Debug output if requested
if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
	# shellcheck disable=SC1091
	echo "DOTFILES_ROOT set to: $DOTFILES_ROOT" >&2
fi

# --- Global Pathing Configuration ---
# Set a default projects directory relative to the user's home if not defined.  Users can override
# PROJECTS_ROOT in their personal .env file.
if [[ -z "${PROJECTS_ROOT:-}" ]]; then
	export PROJECTS_ROOT="$HOME/projects"
fi

# --- WSL Integration Variables ---
# Set default values for WSL-Windows integration, can be overridden in .env files
if [[ -z "${WSL_USER:-}" ]]; then
	export WSL_USER="${USER:-$(id -un 2>/dev/null || whoami)}"
fi

if [[ -z "${WSL_PROJECTS_PATH:-}" ]] && [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	# Default Windows path for projects symlink
	export WSL_PROJECTS_PATH="\$env:USERPROFILE\\projects"
fi

if [[ -z "${WSL_DISTRO:-}" ]] && [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	export WSL_DISTRO="$WSL_DISTRO_NAME"
fi

# --- Environment Variable Loading ---
# Use the new consolidated, secure environment loader that includes validation,
# error handling, and security checks for all environment files.
if [ -f "$DOTFILES_ROOT/lib/env-loader.sh" ]; then
	# shellcheck source=dotfiles-main/lib/env-loader.sh
	# shellcheck disable=SC1091
	. "$DOTFILES_ROOT/lib/env-loader.sh"
	# Load all environment variables with validation and security checks
	load_dotfiles_environment "$DOTFILES_ROOT"
fi

# --- Modular Shell Configuration ---
# Load the new modular configuration system that organizes shell settings
# into common, platform-specific, and shell-specific modules for better maintainability
if [ -f "$DOTFILES_ROOT/shell/loader.sh" ]; then
	# shellcheck source=dotfiles-main/shell/loader.sh
	# shellcheck disable=SC1091
	. "$DOTFILES_ROOT/shell/loader.sh"
fi

# --- Node.js Version Management (Volta) ---
if [ -d "$HOME/.volta" ]; then
	export VOLTA_HOME="$HOME/.volta"
	export PATH="$VOLTA_HOME/bin:$PATH"
fi

# --- Snap Package Manager ---
# Add snap binaries to PATH if snap directory exists
if [ -d "/snap/bin" ]; then
	export PATH="$PATH:/snap/bin"
fi

# --- Legacy Aliases (being migrated to modular system) ---
alias projects='cd "$PROJECTS_ROOT"'
# Clarified dotfiles alias for a standard repo in $HOME/dotfiles
alias dotfiles='git --git-dir="$DOTFILES_ROOT/.git" --work-tree="$DOTFILES_ROOT"'

# --- Conditional Aliases ---
if command -v code >/dev/null; then
	alias pcode='code -n "$PROJECTS_ROOT" --disable-extensions'
fi

# --- Shell-Specific Greetings ---
# Only show greetings in interactive sessions and not during instant prompt
if [[ -z "${P10K_INSTANT_PROMPT:-}" ]] && [[ $- == *i* ]] && [[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]]; then
	# Auto-navigate to home if starting in Windows user directory (common WSL issue)
	if [[ "$PWD" == "/mnt/c/Users/"* ]] && [[ "$PWD" != "$HOME" ]]; then
		cd "$HOME" 2>/dev/null || return
	fi

	if [ -n "$BASH_VERSION" ]; then
		echo "👋 Welcome back, Bash commander."
	elif [ -n "$ZSH_VERSION" ]; then
		echo "✨ All hail the Zsh wizard."
	fi
fi

# --- Hostname-Specific Configuration ---
# Only show hostname messages in interactive sessions and not during instant prompt
case "$(hostname | tr '[:upper:]' '[:lower:]')" in
workstation-name)
	export SPECIAL_VAR="true"
	if [[ -z "${P10K_INSTANT_PROMPT:-}" ]] && [[ $- == *i* ]] && [[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]]; then
		echo "🔒 Loaded workstation-specific config for $(hostname)"
	fi
	;;
dev-laptop)
	export SPECIAL_VAR="false"
	if [[ -z "${P10K_INSTANT_PROMPT:-}" ]] && [[ $- == *i* ]] && [[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]]; then
		echo "🔒 Loaded dev laptop config for $(hostname)"
	fi
	;;
*)
	if [[ -z "${P10K_INSTANT_PROMPT:-}" ]] && [[ $- == *i* ]] && [[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]]; then
		echo "ℹ️  No specific config for $(hostname), loading defaults."
	fi
	;;
esac

# --- WSL2 Integration ---
# Consolidated configuration for WSL2: Kubernetes, SSH, and Projects symlinks.
# Runs only when inside WSL and when cmd.exe is available. Fetch WIN_USER once
# and then perform the per-feature setup steps. This reduces duplication and
# centralizes platform-specific behavior for easier maintenance.
if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
	# Get Windows username safely (do this once)
	WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)

	if [[ -n "$WIN_USER" ]]; then
        
		# --- Kubernetes (kubectl) ---
		WIN_KUBE_CONFIG="/mnt/c/Users/$WIN_USER/.kube/config"
		LOCAL_KUBE_DIR="$HOME/.kube"
		LOCAL_KUBE_CONFIG="$LOCAL_KUBE_DIR/config"

		if [[ -f "$WIN_KUBE_CONFIG" ]]; then
			[[ ! -d "$LOCAL_KUBE_DIR" ]] && mkdir -p "$LOCAL_KUBE_DIR" 2>/dev/null
			if [[ ! -L "$LOCAL_KUBE_CONFIG" ]] || [[ "$(readlink "$LOCAL_KUBE_CONFIG" 2>/dev/null)" != "$WIN_KUBE_CONFIG" ]]; then
				ln -sf "$WIN_KUBE_CONFIG" "$LOCAL_KUBE_CONFIG" 2>/dev/null
			fi
			[[ -f "$LOCAL_KUBE_CONFIG" ]] && chmod 600 "$LOCAL_KUBE_CONFIG" 2>/dev/null
		fi

		# --- SSH Keys ---
		WIN_SSH_DIR="/mnt/c/Users/$WIN_USER/.ssh"
		LOCAL_SSH_DIR="$HOME/.ssh"
		[[ ! -d "$LOCAL_SSH_DIR" ]] && mkdir -p "$LOCAL_SSH_DIR" 2>/dev/null

		declare -a ssh_files=("id_rsa" "id_rsa.pub" "id_ed25519" "id_ed25519.pub" "known_hosts" "config")
		for ssh_file in "${ssh_files[@]}"; do
			WIN_SSH_FILE="$WIN_SSH_DIR/$ssh_file"
			LOCAL_SSH_FILE="$LOCAL_SSH_DIR/$ssh_file"
			if [[ -f "$WIN_SSH_FILE" ]]; then
				if [[ ! -L "$LOCAL_SSH_FILE" ]] || [[ "$(readlink "$LOCAL_SSH_FILE" 2>/dev/null)" != "$WIN_SSH_FILE" ]]; then
					ln -sf "$WIN_SSH_FILE" "$LOCAL_SSH_FILE" 2>/dev/null
				fi
				case "$ssh_file" in
				id_rsa | id_ed25519)
					chmod 600 "$LOCAL_SSH_FILE" 2>/dev/null
					;;
				*.pub)
					chmod 644 "$LOCAL_SSH_FILE" 2>/dev/null
					;;
				known_hosts | config)
					chmod 644 "$LOCAL_SSH_FILE" 2>/dev/null
					;;
				esac
			fi
		done

		# --- Projects Directory Windows Symlink ---
		[[ ! -d "$PROJECTS_ROOT" ]] && mkdir -p "$PROJECTS_ROOT" 2>/dev/null
		WIN_USER_HOME="/mnt/c/Users/$WIN_USER"
		WIN_PROJECTS_LINK="$WIN_USER_HOME/projects"

		if [[ -d "$PROJECTS_ROOT" ]] && [[ ! -e "$WIN_PROJECTS_LINK" ]]; then
			WSL_PROJECTS_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
			if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
				true
			else
				BATCH_FILE="$WIN_USER_HOME/projects.bat"
				cat >"$BATCH_FILE" 2>/dev/null <<'EOF'
@echo off
REM Navigate to WSL2 projects directory
cd /d "\\wsl.localhost\Ubuntu\home\%USERNAME%\projects"
cmd /k
EOF
				chmod +x "$BATCH_FILE" 2>/dev/null
			fi
		fi
	fi
fi
