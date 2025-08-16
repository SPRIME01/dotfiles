# SSH agent bridging for WSL2
#
# Source the unified bridge script if running under WSL2.  The script will
# silently return if WSL2 is not detected.  By sourcing this file from
# `.zshrc` you ensure that agent forwarding works consistently.

if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
	if [[ -f "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh" ]]; then
		# shellcheck source=dotfiles-main/scripts/setup-ssh-agent-bridge.sh
		. "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh"
	fi
fi
