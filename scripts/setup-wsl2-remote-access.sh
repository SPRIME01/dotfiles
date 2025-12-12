#!/usr/bin/env bash
# setup-wsl2-remote-access.sh - Configure remote SSH access to WSL2 instances
# Supports both Tailscale SSH (preferred) and regular SSH
#
# Usage:
#   bash scripts/setup-wsl2-remote-access.sh [--tailscale|--ssh|--help]
#
# Options:
#   --tailscale  Use Tailscale SSH (default, requires tailscale to be installed)
#   --ssh        Use regular SSH (starts sshd, requires manual key management)
#   --help       Show this help message
#
# Environment:
#   TAILSCALE_AUTH_KEY - Optional auth key for non-interactive Tailscale setup
#   SSH_PORT           - SSH port for regular SSH (default: 22)

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
	head -20 "$0" | tail -15
	exit 0
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
	log_info "Setting up Tailscale SSH..."

	# Check if Tailscale is installed
	if ! command -v tailscale &>/dev/null; then
		log_warn "Tailscale not installed. Installing now..."
		if [[ -f "$DOTFILES_ROOT/scripts/install-tailscale.sh" ]]; then
			bash "$DOTFILES_ROOT/scripts/install-tailscale.sh"
		else
			# Fallback to official installer
			curl -fsSL https://tailscale.com/install.sh | sh
		fi
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
	log_info "Connection details:"
	echo "  Hostname: $(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*' | cut -d'"' -f4 || echo "Check 'tailscale status'")"
	echo "  IP: $(tailscale ip -4 2>/dev/null || echo "Check 'tailscale ip'")"
	echo ""
	log_info "To connect from any tailnet device:"
	echo "  ssh $USER@$(hostname) # Using MagicDNS"
	echo "  ssh $USER@$(tailscale ip -4 2>/dev/null) # Using IP"
}

# Setup regular SSH (fallback method)
setup_regular_ssh() {
	log_info "Setting up regular SSH..."

	local ssh_port="${SSH_PORT:-22}"

	# Install openssh-server if not present
	if ! command -v sshd &>/dev/null; then
		log_info "Installing openssh-server..."
		sudo apt-get update -qq
		sudo apt-get install -y openssh-server
	fi

	# Ensure SSH host keys exist
	if [[ ! -f /etc/ssh/ssh_host_rsa_key ]]; then
		log_info "Generating SSH host keys..."
		sudo ssh-keygen -A
	fi

	# Configure sshd for WSL2
	local sshd_config="/etc/ssh/sshd_config"

	# Ensure basic settings
	sudo sed -i 's/#Port 22/Port '"$ssh_port"'/' "$sshd_config" 2>/dev/null || true
	sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$sshd_config" 2>/dev/null || true
	sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$sshd_config" 2>/dev/null || true

	# Start sshd
	if pgrep -x sshd &>/dev/null; then
		log_info "Reloading sshd..."
		sudo systemctl reload sshd 2>/dev/null || sudo kill -HUP "$(pgrep -x sshd)"
	else
		log_info "Starting sshd..."
		sudo systemctl start sshd 2>/dev/null || sudo /usr/sbin/sshd
	fi

	# Get WSL2 IP
	local wsl_ip
	wsl_ip=$(hostname -I | awk '{print $1}')

	echo ""
	log_success "Regular SSH setup complete!"
	echo ""
	log_info "Connection details:"
	echo "  WSL2 IP: $wsl_ip"
	echo "  Port: $ssh_port"
	echo ""
	log_warn "Important: Regular SSH requires manual key management!"
	echo "  1. Copy your public key to: ~/.ssh/authorized_keys"
	echo "  2. Ensure proper permissions: chmod 600 ~/.ssh/authorized_keys"
	echo ""
	log_info "From Windows host: ssh $USER@$wsl_ip -p $ssh_port"
	echo ""
	log_warn "Note: WSL2 IP changes on restart. Consider using Tailscale for stable connectivity."
}

# Main
main() {
	local mode="${1:-tailscale}"

	case "$mode" in
	--help | -h)
		show_help
		;;
	--tailscale | -t | tailscale)
		check_wsl
		setup_tailscale_ssh
		;;
	--ssh | -s | ssh)
		check_wsl
		setup_regular_ssh
		;;
	*)
		log_error "Unknown option: $mode"
		log_info "Use --help for usage information"
		exit 1
		;;
	esac
}

main "$@"
