#!/usr/bin/env bash
# Test: Verify checksum enforcement for oh-my-posh installer
# Uses existing installed binary to obtain expected hash and performs reinstall via local file path.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$DOTFILES_DIR/scripts/install-oh-my-posh.sh"

if ! command -v oh-my-posh >/dev/null 2>&1; then
  echo "SKIP: oh-my-posh not present to derive checksum"
  exit 0
fi

BIN_PATH="$(command -v oh-my-posh)"
HASH=$(sha256sum "$BIN_PATH" | awk '{print $1}')
TMP_COPY=$(mktemp)
cp "$BIN_PATH" "$TMP_COPY"

# Run installer using local file + expected hash (forces reinstall by bumping temp version var)
OMP_VERSION="v24.9.0" OMP_LOCAL_FILE="$TMP_COPY" OMP_EXPECTED_SHA256="$HASH" bash "$INSTALLER" >/dev/null 2>&1 || {
  echo "FAIL: installer failed with valid checksum"; exit 1; }

echo "PASS: checksum verified successfully"
