#!/usr/bin/env bash
# Description: Install or update oh-my-posh with version pin & checksum verification.
# Category: dependency
# Dependencies: curl, sha256sum, tar
# Idempotent: yes (skips if already at target version)
# Inputs: OMP_VERSION (override), OMP_BIN (path override), OMP_EXPECTED_SHA256 (checksum), OMP_LOCAL_FILE (offline install)
# Outputs: Installed oh-my-posh binary (verified)
# Exit Codes: 0 success, >0 failure
set -euo pipefail

# Logging support
if [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/log.sh" ]; then
  # shellcheck disable=SC1090
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/log.sh"
fi

if [[ "${OMP_VERSION:-}" == "skip" ]]; then
  log_info "Skipping oh-my-posh install due to OMP_VERSION=skip"
  exit 0
fi
TARGET_VERSION="${OMP_VERSION:-v24.9.0}" # Pinned version
BINARY_NAME="oh-my-posh"
INSTALL_DIR="$HOME/.local/bin"
BIN_PATH="${OMP_BIN:-$INSTALL_DIR/$BINARY_NAME}"
EXPECTED_SHA256="${OMP_EXPECTED_SHA256:-}"
LOCAL_FILE="${OMP_LOCAL_FILE:-}"

mkdir -p "$INSTALL_DIR"

verify_checksum() {
  local file=$1 expected=$2
  if [[ -z "$expected" ]]; then
  log_warn "No expected checksum provided; skipping verification"
    return 0
  fi
  if ! command -v sha256sum >/dev/null 2>&1; then
  log_warn "sha256sum not available; cannot verify checksum"
    return 0
  fi
  local actual
  actual=$(sha256sum "$file" | awk '{print $1}')
  if [[ "$actual" != "$expected" ]]; then
  log_error "Checksum mismatch for $file"
  log_error "Expected: $expected"
  log_error "Actual:   $actual"
    return 1
  fi
  log_info "Checksum verified ($actual)"
}

need_install=true
if command -v "$BINARY_NAME" >/dev/null 2>&1; then
  current=$($BINARY_NAME version 2>/dev/null || true)
  if [[ "$current" == *"$TARGET_VERSION"* ]]; then
  log_info "oh-my-posh already at $TARGET_VERSION"; need_install=false
  fi
fi

if $need_install; then
  log_info "Installing oh-my-posh $TARGET_VERSION"
  tmpfile=$(mktemp)
  if [[ -n "$LOCAL_FILE" ]]; then
  log_info "Using local file: $LOCAL_FILE"
    cp "$LOCAL_FILE" "$tmpfile"
  else
    url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/${TARGET_VERSION}/posh-linux-amd64"
  log_info "Downloading from $url"
    curl -fsSL "$url" -o "$tmpfile"
  fi
  verify_checksum "$tmpfile" "$EXPECTED_SHA256"
  chmod +x "$tmpfile"
  mv "$tmpfile" "$BIN_PATH"
  log_info "Installed $BIN_PATH"
else
  log_info "Skipping installation"
fi

# Print version for verification
$BINARY_NAME version || true
