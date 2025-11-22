#!/usr/bin/env bash
# lib/secure-install.sh - Secure installer with checksum verification
# Prevents man-in-the-middle attacks and arbitrary code execution

set -euo pipefail

# Secure installer with checksum verification
# Usage: secure_install URL EXPECTED_SHA256 [INSTALL_ARGS...]
secure_install() {
  local url="$1"
  local expected_sha256="$2"
  shift 2
  local install_args=("$@")
  
  # Create temporary directory
  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  
  local script_file="$tmpdir/installer.sh"
  
  echo "📥 Downloading from: $url"
  
  # Download with HTTPS enforcement
  if ! curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$script_file"; then
    echo "❌ ERROR: Failed to download $url" >&2
    return 1
  fi
  
  # Verify checksum if provided
  if [[ -n "$expected_sha256" && "$expected_sha256" != "skip" ]]; then
    local actual_sha256
    actual_sha256="$(sha256sum "$script_file" | cut -d' ' -f1)"
    
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
      echo "❌ ERROR: Checksum verification failed!" >&2
      echo "  Expected: $expected_sha256" >&2
      echo "  Actual:   $actual_sha256" >&2
      return 2
    fi
    echo "✅ Checksum verified"
  else
    echo "⚠️  WARNING: Skipping checksum verification (not recommended)" >&2
  fi
  
  # Execute verified script
  chmod +x "$script_file"
  bash "$script_file" "${install_args[@]}"
}

# Fetch and display checksum for a URL (helper for updating checksums)
fetch_checksum() {
  local url="$1"
  echo "Fetching checksum for: $url"
  local checksum
  checksum="$(curl --proto '=https' --tlsv1.2 -fsSL "$url" | sha256sum | cut -d' ' -f1)"
  echo "SHA256: $checksum"
}
