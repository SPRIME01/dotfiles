#!/usr/bin/env bash

# --- Determine Dotfiles Root (bash + zsh safe) ---
# Always derive DOTFILES_ROOT from the location of this file to ensure accuracy.
# Handles being sourced from either bash or zsh without relying on PWD.
if [[ -n "${DOTFILES_ROOT:-}" && -d "${DOTFILES_ROOT}/.git" ]] || [[ -f "${DOTFILES_ROOT:-}/.shell_common.sh" ]]; then
    : # Respect pre-set DOTFILES_ROOT if it looks valid
else
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        # In zsh, ${(%):-%N} expands to the current script path even when sourced
        # Use eval so this branch remains portable when parsed by bash
        eval '___df_script_path="${(%):-%N}"'
        DOTFILES_ROOT="$(cd "$(dirname "${___df_script_path:-$0}")" && pwd)"
        unset ___df_script_path
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
    else
        # Fallback: guess common location
        DOTFILES_ROOT="${HOME}/dotfiles"
    fi
fi
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

# --- Auto-sync environment to systemd (for GUI apps like VS Code) ---
# Automatically sync .env changes to systemd user environment so GUI applications
# can access environment variables without needing to be launched from terminal
if [ -f "$DOTFILES_ROOT/scripts/auto-sync-env.sh" ]; then
	# shellcheck source=dotfiles-main/scripts/auto-sync-env.sh
	# shellcheck disable=SC1091
	. "$DOTFILES_ROOT/scripts/auto-sync-env.sh"
fi

# --- Modular Shell Configuration ---
# Load the new modular configuration system that organizes shell settings
# into common, platform-specific, and shell-specific modules for better maintainability
if [ -f "$DOTFILES_ROOT/shell/loader.sh" ]; then
	# shellcheck source=dotfiles-main/shell/loader.sh
	# shellcheck disable=SC1091
	. "$DOTFILES_ROOT/shell/loader.sh"
fi

# --- Snap Package Manager ---
# Note: Snap PATH management is now handled by platform-specific templates

# --- Legacy Aliases (being migrated to modular system) ---
alias projects='cd "$PROJECTS_ROOT"'
# Clarified dotfiles alias for a standard repo in $HOME/dotfiles
alias dotfiles='git --git-dir="$DOTFILES_ROOT/.git" --work-tree="$DOTFILES_ROOT"'
alias cddot='cd "$DOTFILES_ROOT"'

# --- Environment Sync Aliases ---
# Sync environment variables to systemd so GUI apps (VS Code, etc.) can access them
alias sync-env='bash "$DOTFILES_ROOT/scripts/sync-env-to-systemd.sh"'
alias reload-vscode='echo "Close VS Code, then run: code" && echo "Or use Ctrl+Shift+P → Developer: Reload Window"'

# --- Conditional Aliases ---
if command -v code >/dev/null; then
	alias pcode='code -n "$PROJECTS_ROOT" --disable-extensions'
fi

# --- Hostname-Specific Configuration ---
__dotfiles_hostname="$(hostname 2>/dev/null || true)"
__dotfiles_hostname_lower="$(printf '%s' "$__dotfiles_hostname" | tr '[:upper:]' '[:lower:]')"
__DOTFILES_HOST_MESSAGE=""
case "$__dotfiles_hostname_lower" in
workstation-name)
	export SPECIAL_VAR="true"
	__DOTFILES_HOST_MESSAGE="🔒 Loaded workstation-specific config for $__dotfiles_hostname"
	;;
dev-laptop)
	export SPECIAL_VAR="false"
	__DOTFILES_HOST_MESSAGE="🔒 Loaded dev laptop config for $__dotfiles_hostname"
	;;
*)
	__DOTFILES_HOST_MESSAGE="ℹ️  No specific config for $__dotfiles_hostname, loading defaults."
	;;
esac
unset __dotfiles_hostname_lower

# --- Shell-Specific Greetings ---
# Delay greeting until after prompt to keep Powerlevel10k instant prompt quiet
__dotfiles_show_shell_greeting() {
	# Skip greeting if already shown or in VS Code terminal to avoid P10k instant prompt issues
	if [[ -n "${__DOTFILES_GREETING_SHOWN:-}" ]] || [[ "${TERM_PROGRAM:-}" == "vscode" ]]; then
		return
	fi
	local lines=()
	if [[ -n "${BASH_VERSION:-}" ]]; then
		lines+=("👋 Welcome back, Bash commander.")
	elif [[ -n "${ZSH_VERSION:-}" ]]; then
		lines+=("✨ All hail the Zsh wizard.")
	fi
	if [[ -n "${__DOTFILES_HOST_MESSAGE:-}" ]]; then
		lines+=("${__DOTFILES_HOST_MESSAGE}")
	fi
	if (( ${#lines[@]} > 0 )); then
		printf '%s\n' "${lines[@]}"
	fi
	__DOTFILES_GREETING_SHOWN=1
	unset __DOTFILES_HOST_MESSAGE
	if [[ -n "${ZSH_VERSION:-}" ]]; then
		add-zsh-hook -d precmd __dotfiles_show_shell_greeting 2>/dev/null || true
	fi
}

__dotfiles_schedule_greeting() {
	if [[ -n "${__DOTFILES_GREETING_SCHEDULED:-}" ]]; then
		return
	fi
	__DOTFILES_GREETING_SCHEDULED=1
	if [[ -n "${ZSH_VERSION:-}" ]]; then
		autoload -Uz add-zsh-hook 2>/dev/null || return
		add-zsh-hook -Uz precmd __dotfiles_show_shell_greeting
	elif [[ -n "${BASH_VERSION:-}" ]]; then
		case ";${PROMPT_COMMAND:-};" in
		*";__dotfiles_show_shell_greeting;"*) ;;
		*)
			if [[ -n "${PROMPT_COMMAND:-}" ]]; then
				PROMPT_COMMAND="__dotfiles_show_shell_greeting;${PROMPT_COMMAND}"
			else
				PROMPT_COMMAND="__dotfiles_show_shell_greeting"
			fi
			export PROMPT_COMMAND
			;;
		esac
	fi
}

if [[ $- == *i* ]]; then
    if [[ "$PWD" == "/mnt/c/Users/"* ]] && [[ "$PWD" != "$HOME" ]]; then
        cd "$HOME" 2>/dev/null || true
    fi

    case "${DOTFILES_FORCE_SHELL_GREETING:-}" in
        1|true|TRUE|yes|YES)
            __dotfiles_schedule_greeting
            ;;
        *)
            if [[ "${POWERLEVEL9K_INSTANT_PROMPT:-off}" == "off" ]]; then
                __dotfiles_schedule_greeting
            else
                unset __DOTFILES_HOST_MESSAGE
            fi
            ;;
    esac
fi

unset __dotfiles_hostname

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

        # --- SSH (best practice for WSL) ---
        # Keep ~/.ssh as native ext4 files to satisfy OpenSSH StrictModes.
        # Do NOT symlink private keys or config from /mnt/c.
        LOCAL_SSH_DIR="$HOME/.ssh"
        [[ ! -d "$LOCAL_SSH_DIR" ]] && mkdir -p "$LOCAL_SSH_DIR" 2>/dev/null
        chmod 700 "$LOCAL_SSH_DIR" 2>/dev/null || true
        # If known_hosts is missing, copy once from Windows for convenience.
        if [[ ! -e "$LOCAL_SSH_DIR/known_hosts" ]]; then
            WIN_KNOWN_HOSTS="/mnt/c/Users/$WIN_USER/.ssh/known_hosts"
            [[ -f "$WIN_KNOWN_HOSTS" ]] && cp "$WIN_KNOWN_HOSTS" "$LOCAL_SSH_DIR/known_hosts" 2>/dev/null || true
            [[ -f "$LOCAL_SSH_DIR/known_hosts" ]] && chmod 644 "$LOCAL_SSH_DIR/known_hosts" 2>/dev/null || true
        fi

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
                cat >"$BATCH_FILE" 2>/dev/null <<EOF
@echo off
REM Navigate to WSL2 projects directory
cd /d "\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
cmd /k
EOF
                chmod +x "$BATCH_FILE" 2>/dev/null
            fi
        fi

        # --- Convenience alias to Windows home ---
        if [[ -n "$WIN_USER" ]]; then
            alias winhome="cd /mnt/c/Users/$WIN_USER"
        fi
    fi
fi
