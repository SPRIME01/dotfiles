#!/usr/bin/env bash
# Unified setup script for forwarding the Windows OpenSSH agent into WSL2.
#
# This script encapsulates the logic previously duplicated in `.bashrc` and
# `.zshrc` to bridge the Windows OpenSSH agent through `npiperelay` and
# `socat` into WSL.  It is idempotent and can be safely called multiple
# times in a single session.  It will only start a bridge if running under
# WSL2 and if the socket is not already active.

# Path to the Unix socket that will be used by SSH clients inside WSL
# Standardize on ~/.ssh/agent.sock to match other tooling in this repo.
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$HOME/.ssh/agent.sock}"

setup_ssh_agent_bridge() {
	# Only run on WSL2
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
		return 0
	fi

	# Start wsl-ssh-agent-relay if installed
	if command -v wsl-ssh-agent-relay >/dev/null 2>&1; then
		wsl-ssh-agent-relay start || true
	fi

	# Determine path to npiperelay on Windows using USERPROFILE and wslpath
	local userprofile_win
	userprofile_win=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
	local userprofile
	userprofile="$(wslpath "$userprofile_win")"
	local npiperelay="${NPIPERELAY:-$userprofile/scoop/apps/npiperelay/0.1.0/npiperelay.exe}"
	if [[ ! -x "$npiperelay" ]]; then
		# Only show error message in interactive mode and not during instant prompt
		if [[ -z "${P10K_INSTANT_PROMPT:-}" ]] && [[ $- == *i* ]] && [[ -z "${POWERLEVEL9K_INSTANT_PROMPT:-}" ]]; then
			echo "[setup-ssh-agent-bridge] npiperelay not found at $npiperelay" >&2
		fi
		return 0
	fi

	# Helper to check if the socket is already live
	is_socket_active() {
		[[ -S "$SSH_AUTH_SOCK" ]] && ssh-add -l >/dev/null 2>&1
	}

	# Only start socat if socket not alive
	if ! is_socket_active; then
		rm -f "$SSH_AUTH_SOCK"
		# Use setsid and nohup to detach from the current process; disown to avoid job notifications
		# Use portable backgrounding; avoid shell-specific '&!' token which breaks shfmt
		setsid nohup socat \
			UNIX-LISTEN:"$SSH_AUTH_SOCK",fork \
			EXEC:"$npiperelay //./pipe/openssh-ssh-agent" \
			>/dev/null 2>&1 &
		bgpid=$!
		# Best-effort: remove job from shell job table to suppress job notifications
		{ builtin disown "$bgpid" 2>/dev/null || disown "$bgpid" 2>/dev/null || true; }
	fi
}

# Execute the function when sourced or run directly
setup_ssh_agent_bridge
