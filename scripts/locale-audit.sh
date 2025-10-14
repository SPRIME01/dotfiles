#!/usr/bin/env bash
# Locale Audit: Scan repo and common config locations for locale settings
# Usage:
#   ./locale-audit.sh            # scan repo + common system/user files
#   ./locale-audit.sh --repo     # scan only the repo
#   ./locale-audit.sh --system   # scan /etc and user config files

set -euo pipefail

SCOPE="${1:-all}"
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

scan_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    grep -nE "en_US.UTF-8|C.UTF-8|LC_ALL|LANG" "$f" || true
  fi
}

log() { echo "[locale-audit] $*"; }

if [[ "$SCOPE" == "all" || "$SCOPE" == "repo" ]]; then
  log "Scanning repository: $REPO_ROOT"
  rg -n --hidden --no-ignore -S "en_US.UTF-8|C.UTF-8|LC_ALL|LANG" "$REPO_ROOT" || true
fi

if [[ "$SCOPE" == "all" || "$SCOPE" == "system" ]]; then
  log "Scanning common system/user files"
  scan_file /etc/default/locale
  scan_file /etc/locale.conf
  scan_file ~/.pam_environment
  scan_file ~/.profile
  scan_file ~/.bashrc
  scan_file ~/.zshenv
  scan_file ~/.zprofile
  scan_file ~/.bash_profile
  scan_file /etc/environment
fi

log "Done"
