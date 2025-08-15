#!/usr/bin/env bash
# Description: Safe dependency installer for optional tools (socat, openssh components) with systemd detection.
# Category: setup
# Dependencies: apt, bash
# Idempotent: yes (skips already installed packages)
# Inputs: environment (root privileges required; will auto-elevate with sudo if available)
# Outputs: Installed packages where appropriate
# Exit Codes: 0 success, >0 failure
set -euo pipefail
_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "$_ROOT/lib/log.sh" ]]; then
  # shellcheck source=/dev/null
  source "$_ROOT/lib/log.sh"
else
  log_debug() { echo "[DEBUG] $*" >&2; }
  log_info()  { echo "[INFO ] $*"  >&2; }
  log_warn()  { echo "[WARN ] $*"  >&2; }
  log_error() { echo "[ERROR] $*"  >&2; }
fi

# Ensure apt-get is present; otherwise skip gracefully.
if ! command -v apt-get >/dev/null 2>&1; then
  log_warn "apt-get not available; skipping dependency installation."
  exit 0
fi

need_root() { [ "${EUID:-$(id -u)}" -ne 0 ]; }

if need_root; then
  # If sudo is available, re-exec the script elevated preserving the environment.
  if command -v sudo >/dev/null 2>&1; then
    log_info "Root privileges required — elevating with sudo..."
    exec sudo -E bash "$0" "$@"
  else
    cat <<'MSG' >&2
Root privileges are required for package installation.
Re-run with sudo, for example:
  sudo bash ./scripts/install-dependencies.sh
MSG
    exit 1
  fi
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
# Make update quieter in CI; apt-get update doesn't require -y. Use -qq to reduce noise.
apt-get update -qq

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
  # Install non-interactively and quietly so CI won't hang on prompts.
  if ! DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${install_list[@]}"; then
    log_error "Failed installing: ${install_list[*]}" >&2
    exit 2
  fi
else
  log_info "All target packages already present"
fi

log_info "Dependency installation complete"
  log_info "All target packages already present"
fi

log_info "Dependency installation complete"
