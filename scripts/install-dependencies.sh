#!/usr/bin/env bash
# Description: Safe dependency installer for optional tools (socat, openssh components) with systemd detection.
# Category: setup
# Dependencies: apt, bash
# Idempotent: yes (skips already installed packages)
# Inputs: environment (root privileges recommended)
# Outputs: Installed packages where appropriate
# Exit Codes: 0 success, >0 failure
set -euo pipefail
[[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/log.sh" ]] && source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/log.sh"

if ! command -v apt-get >/dev/null 2>&1; then
  log_warn "apt-get not available; skipping dependency installation."; exit 0
fi

need_root() { [ "${EUID:-$(id -u)}" -ne 0 ]; }

if need_root; then
  log_warn "Root privileges required for package installation. Re-run with sudo." >&2
  exit 1
fi

SYSTEMD_PRESENT=false
if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
  SYSTEMD_PRESENT=true
fi

PKGS=(socat openssh-client)
# Only include server if systemd present (so service postinst doesn't fail)
if $SYSTEMD_PRESENT; then
  PKGS+=(openssh-server)
else
  log_info "Systemd not detected; skipping openssh-server."
fi

log_info "Updating package index"
apt-get update -y >/dev/null

install_list=()
for pkg in "${PKGS[@]}"; do
  if dpkg -s "$pkg" >/dev/null 2>&1; then
  log_debug "$pkg already installed"
  else
    install_list+=("$pkg")
  fi
done

if ((${#install_list[@]})); then
  log_info "Installing packages: ${install_list[*]}"
  if ! apt-get install -y "${install_list[@]}"; then
  log_error "Failed installing: ${install_list[*]}" >&2
    exit 2
  fi
else
  log_info "All target packages already present"
fi

log_info "Dependency installation complete"
