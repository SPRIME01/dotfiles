#!/usr/bin/env bash
# setup-wsl2-remote-access.sh - Configure remote SSH access to WSL2 via Tailscale
#
# This script sets up Tailscale SSH for secure remote access to WSL2 instances.
# Tailscale SSH eliminates the need for key management and provides end-to-end
# encryption via WireGuard®. It also works with VS Code Remote-SSH extension.
#
# Features:
#   - Automatic machine audit (checks what needs to be configured)
#   - Idempotent VS Code Remote-SSH configuration (~/.ssh/config)
#   - Tailscale SSH setup and verification
#
# Usage:
#   bash scripts/setup-wsl2-remote-access.sh [--help|--audit|--setup]
#
# Options:
#   --audit  Show current configuration status (default if already configured)
#   --setup  Force setup/repair even if already configured
#   --help   Show this help message
#
# Environment:
#   TAILSCALE_AUTH_KEY - Optional auth key for non-interactive Tailscale setup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="${DOTFILES_ROOT:-$(dirname "$SCRIPT_DIR")}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}" >&2; }

show_help() {
	head -30 "$0" | tail -23
	exit 0
}

# Audit current configuration state
audit_configuration() {
	local issues=0
	echo ""
	log_info "=== Machine Configuration Audit ==="
	echo ""

	# Check 1: WSL2 Environment
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
		log_error "Not running in WSL2"
		((issues++))
	else
		log_success "WSL2 detected: $WSL_DISTRO_NAME"
	fi

	# Check 2: Tailscale installation (in WSL2, not Windows)
	local ts_path
	ts_path=$(command -v tailscale 2>/dev/null || echo "")

	if [[ -z "$ts_path" ]]; then
		log_warn "Tailscale not installed in WSL2"
		((issues++))
	elif [[ "$ts_path" =~ /mnt/c/ ]]; then
		log_warn "Tailscale command is from Windows (not WSL2)"
		echo "  → Found at: $ts_path"
		echo "  → Need native WSL2 installation"
		((issues++))
	else
		log_success "Tailscale installed in WSL2: $(tailscale version --short 2>/dev/null || echo 'unknown version')"
		echo "  → Binary at: $ts_path"
	fi

	# Check 3: Tailscale daemon (must be WSL2 process, not Windows)
	if ! pgrep -x tailscaled &>/dev/null; then
		log_warn "Tailscaled daemon not running in WSL2"
		((issues++))
	else
		log_success "Tailscaled daemon running in WSL2"
	fi

	# Check 4: Tailscale authentication and SSH
	if command -v tailscale &>/dev/null; then
		local status
		status=$(tailscale status 2>&1 || echo "error")

		if echo "$status" | grep -q "Logged out"; then
			log_warn "Tailscale not authenticated"
			((issues++))
		else
			# Check for SSH capability - try JSON method first
			local ssh_enabled=false
			if command -v jq &>/dev/null; then
				if tailscale status --json 2>/dev/null | jq -e '.Self.CapMap["https://tailscale.com/cap/ssh"]' &>/dev/null; then
					ssh_enabled=true
				fi
			fi

			# Fallback: check for SSH in status output or check for ssh-behavior capability
			if [[ "$ssh_enabled" == false ]]; then
				if echo "$status" | grep -iq "ssh"; then
					ssh_enabled=true
				elif tailscale status --json 2>/dev/null | grep -q '"ssh-behavior-v1"'; then
					ssh_enabled=true
				fi
			fi

			if [[ "$ssh_enabled" == true ]]; then
				log_success "Tailscale SSH enabled"
				local ts_hostname
				ts_hostname=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | cut -d'"' -f4 | head -1 || echo "")
				[[ -z "$ts_hostname" ]] && ts_hostname=$(tailscale status 2>/dev/null | grep "^100\." | head -1 | awk '{print $2}' || echo "unknown")
				local ts_ip
				ts_ip=$(tailscale ip -4 2>/dev/null | head -1 || echo "unknown")
				echo "  → Hostname: $ts_hostname"
				echo "  → IP: $ts_ip"
			else
				log_warn "Tailscale SSH not enabled"
				((issues++))
			fi
		fi
	fi

	# Check 5: SSH config directory
	if [[ ! -d "$HOME/.ssh" ]]; then
		log_warn "~/.ssh directory missing"
		((issues++))
	else
		log_success "~/.ssh directory exists"
	fi

	# Check 6: VS Code Remote-SSH configuration
	local ssh_config="$HOME/.ssh/config"
	local hostname_short
	hostname_short=$(hostname)
	local wsl_host_entry="wsl-$hostname_short"

	if [[ -f "$ssh_config" ]] && grep -q "Host $wsl_host_entry" "$ssh_config"; then
		log_success "VS Code Remote-SSH configured for $wsl_host_entry"
		echo "  → Config entry found in $ssh_config"
	else
		log_warn "VS Code Remote-SSH not configured"
		echo "  → No entry for '$wsl_host_entry' in ~/.ssh/config"
		((issues++))
	fi

	# Check 7: SSH config permissions
	if [[ -f "$ssh_config" ]]; then
		local perms
		perms=$(stat -c "%a" "$ssh_config" 2>/dev/null || stat -f "%Lp" "$ssh_config" 2>/dev/null || echo "unknown")
		if [[ "$perms" == "600" ]] || [[ "$perms" == "644" ]]; then
			log_success "SSH config has correct permissions ($perms)"
		else
			log_warn "SSH config has incorrect permissions: $perms (expected 600 or 644)"
			((issues++))
		fi
	fi

	echo ""
	if ((issues == 0)); then
		log_success "All checks passed! Your machine is properly configured."
		return 0
	else
		log_warn "Found $issues issue(s) that need attention."
		echo ""
		log_info "Run with --setup to automatically fix these issues."
		return 1
	fi
}

# Check if running in WSL2
check_wsl() {
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
		log_error "This script is designed for WSL2. WSL_DISTRO_NAME not detected."
		exit 1
	fi
	log_info "Running in WSL2 distro: $WSL_DISTRO_NAME"
}

# Setup Tailscale SSH (preferred method)
setup_tailscale_ssh() {
	log_info "Setting up Tailscale SSH in WSL2..."

	# Check if Tailscale is installed in WSL2 (not Windows interop)
	local ts_path
	ts_path=$(command -v tailscale 2>/dev/null || echo "")

	if [[ -z "$ts_path" ]] || [[ "$ts_path" =~ /mnt/c/ ]]; then
		if [[ "$ts_path" =~ /mnt/c/ ]]; then
			log_warn "Found Windows Tailscale at $ts_path, but need WSL2 installation"
		else
			log_warn "Tailscale not found in WSL2"
		fi
		log_info "Installing Tailscale in WSL2..."

		if [[ -f "$DOTFILES_ROOT/scripts/install-tailscale.sh" ]]; then
			bash "$DOTFILES_ROOT/scripts/install-tailscale.sh"
		else
			# Fallback to official installer
			log_info "Downloading Tailscale installer..."
			curl -fsSL https://tailscale.com/install.sh | sh
		fi

		# Verify installation succeeded
		if ! command -v tailscale &>/dev/null; then
			log_error "Failed to install Tailscale in WSL2"
			exit 1
		fi
		log_success "Tailscale installed successfully in WSL2"
	else
		log_info "Tailscale already installed at: $ts_path"
	fi

	# Check if tailscaled is running
	if ! pgrep -x tailscaled &>/dev/null; then
		log_info "Starting tailscaled service..."
		sudo systemctl start tailscaled 2>/dev/null || sudo tailscaled &
		sleep 2
	fi

	# Check current status
	local status
	status=$(tailscale status 2>&1 || true)

	if echo "$status" | grep -q "Logged out"; then
		log_info "Tailscale not authenticated. Running tailscale up..."

		local up_args="--ssh --advertise-tags=tag:homelab-wsl2"

		# Use auth key if available
		if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
			log_info "Using TAILSCALE_AUTH_KEY for authentication"
			up_args="$up_args --auth-key=$TAILSCALE_AUTH_KEY"
		else
			log_warn "No TAILSCALE_AUTH_KEY found. You'll need to authenticate interactively."
			log_info "Tip: Set TAILSCALE_AUTH_KEY in .env or run: just secrets-add TAILSCALE_AUTH_KEY"
		fi

		# shellcheck disable=SC2086 # Intentional word splitting
		sudo tailscale up $up_args
	elif ! echo "$status" | grep -q "SSH"; then
		log_info "Enabling Tailscale SSH..."
		sudo tailscale up --ssh --advertise-tags=tag:homelab-wsl2
	else
		log_success "Tailscale SSH is already configured"
	fi

	# Display connection info
	echo ""
	log_success "Tailscale SSH setup complete!"
	echo ""

	# Get hostname using robust method
	local ts_hostname=""
	if command -v jq &>/dev/null; then
		ts_hostname=$(tailscale status --self --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null || echo "")
	fi
	if [[ -z "$ts_hostname" ]]; then
		ts_hostname=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | cut -d'"' -f4 | head -1 || echo "")
	fi
	if [[ -z "$ts_hostname" ]]; then
		local ts_ip
		ts_ip=$(tailscale ip -4 2>/dev/null | head -1 || echo "")
		if [[ -n "$ts_ip" ]]; then
			ts_hostname=$(tailscale status 2>/dev/null | grep "^${ts_ip}" | awk '{print $2}' || echo "")
		fi
	fi
	[[ -z "$ts_hostname" ]] && ts_hostname="(check 'tailscale status')"

	local ts_ip
	ts_ip=$(tailscale ip -4 2>/dev/null | head -1 || echo "(check 'tailscale ip')")

	log_info "Connection details:"
	echo "  Hostname: $ts_hostname"
	echo "  IP: $ts_ip"
	echo ""
	log_info "To connect from any tailnet device:"
	echo "  ssh $USER@$(hostname) # Using MagicDNS"
	echo "  ssh $USER@$ts_ip # Using IP"
}

# Configure VS Code Remote-SSH (idempotent)
configure_vscode_ssh() {
	log_info "Configuring VS Code Remote-SSH..."

	# Ensure .ssh directory exists with correct permissions
	mkdir -p "$HOME/.ssh"
	chmod 700 "$HOME/.ssh"

	local ssh_config="$HOME/.ssh/config"
	local hostname_short
	hostname_short=$(hostname)
	local wsl_host_entry="wsl-$hostname_short"

	# Get Tailscale hostname - try multiple methods
	local ts_hostname=""

	# Method 1: Try JSON output with jq
	if command -v jq &>/dev/null; then
		ts_hostname=$(tailscale status --self --json 2>/dev/null | jq -r '.Self.DNSName // empty' 2>/dev/null || echo "")
	fi

	# Method 2: Parse JSON manually (without jq)
	if [[ -z "$ts_hostname" ]]; then
		ts_hostname=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | cut -d'"' -f4 | head -1 || echo "")
	fi

	# Method 3: Try status output and grep for current machine
	if [[ -z "$ts_hostname" ]]; then
		local ts_ip
		ts_ip=$(tailscale ip -4 2>/dev/null | head -1 || echo "")
		if [[ -n "$ts_ip" ]]; then
			# Find the line with our IP and extract the name
			ts_hostname=$(tailscale status 2>/dev/null | grep "^${ts_ip}" | awk '{print $2}' || echo "")
		fi
	fi

	# Method 4: Fallback to constructed MagicDNS name
	if [[ -z "$ts_hostname" ]]; then
		local ts_name
		ts_name=$(tailscale status 2>/dev/null | grep "^100\." | head -1 | awk '{print $2}' || echo "")
		if [[ -n "$ts_name" ]]; then
			# MagicDNS format is typically: <name>.tailnet-name.ts.net
			log_warn "Could not get full DNS name, using short name: $ts_name"
			ts_hostname="$ts_name"
		fi
	fi

	# Method 5: Last resort - use IP address
	if [[ -z "$ts_hostname" ]]; then
		ts_hostname=$(tailscale ip -4 2>/dev/null | head -1 || echo "")
		if [[ -n "$ts_hostname" ]]; then
			log_warn "Using Tailscale IP address instead of hostname: $ts_hostname"
		else
			log_error "Failed to retrieve Tailscale hostname or IP. Is Tailscale authenticated?"
			log_info "Try running: sudo tailscale up --ssh"
			return 1
		fi
	fi

	# Check if entry already exists
	if [[ -f "$ssh_config" ]] && grep -q "^Host $wsl_host_entry$" "$ssh_config"; then
		log_info "VS Code SSH config already exists for $wsl_host_entry"

		# Check if it needs updating (extract the block for this host)
		local existing_hostname
		existing_hostname=$(awk "/^Host $wsl_host_entry$/,/^(Host |$)/ { if (/^[[:space:]]*HostName/) { print \$2; exit } }" "$ssh_config")

		if [[ "$existing_hostname" == "$ts_hostname" ]]; then
			log_success "VS Code SSH config is up to date"
			return 0
		else
			log_warn "VS Code SSH config exists but hostname doesn't match."
			log_info "  Current: $existing_hostname"
			log_info "  Expected: $ts_hostname"
			log_info "  Updating configuration..."

			# Remove old entry (everything from "Host wsl-..." until next Host or end of file)
			local temp_config
			temp_config=$(mktemp)
			awk "/^Host $wsl_host_entry$/,/^Host / { if (/^Host / && !/^Host $wsl_host_entry$/) print; next } { print }" "$ssh_config" > "$temp_config"
			# Remove trailing blank lines that might be left
			sed -i -e :a -e '/^\s*$/d;N;ba' "$temp_config"
			mv "$temp_config" "$ssh_config"
		fi
	fi

	# Create or append config entry
	log_info "Adding VS Code SSH config entry..."

	# Backup existing config
	if [[ -f "$ssh_config" ]]; then
		cp "$ssh_config" "${ssh_config}.backup.$(date +%Y%m%d_%H%M%S)"
	fi

	# Append new config (with blank line separator if file exists and isn't empty)
	{
		if [[ -f "$ssh_config" ]] && [[ -s "$ssh_config" ]] && ! tail -1 "$ssh_config" | grep -q "^$"; then
			echo ""
		fi
		echo "# WSL2 via Tailscale - Auto-configured by dotfiles"
		echo "# $(date -Iseconds)"
		echo "Host $wsl_host_entry"
		echo "    HostName $ts_hostname"
		echo "    User $USER"
		echo "    # Tailscale handles authentication - no keys needed"
		echo ""
	} >>"$ssh_config"

	# Set correct permissions
	chmod 600 "$ssh_config"

	log_success "VS Code SSH config created!"
	echo ""
	log_info "To connect from VS Code:"
	echo "  1. Install 'Remote - SSH' extension"
	echo "  2. Press F1 → 'Remote-SSH: Connect to Host'"
	echo "  3. Select '$wsl_host_entry'"
	echo ""
	log_info "Config file: $ssh_config"
}

# Main
main() {
	local mode="${1:-auto}"

	case "$mode" in
	--help | -h)
		show_help
		;;
	--audit | -a)
		check_wsl
		audit_configuration
		;;
	--setup | -s)
		check_wsl
		setup_tailscale_ssh
		configure_vscode_ssh
		echo ""
		log_info "Running final audit..."
		audit_configuration
		;;
	--auto | auto | "")
		check_wsl
		# Auto mode: audit first, then decide
		if audit_configuration; then
			log_info "No setup needed. Rerun with --setup to force reconfiguration."
		else
			echo ""
			log_info "Issues detected. Running setup..."
			echo ""
			setup_tailscale_ssh
			configure_vscode_ssh
			echo ""
			log_info "Running final audit..."
			audit_configuration
		fi
		;;
	*)
		log_error "Unknown option: $mode"
		log_info "Use --help for usage information"
		exit 1
		;;
	esac
}

main "$@"
