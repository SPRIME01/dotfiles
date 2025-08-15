#!/usr/bin/env bash
# Test: Verify checksum enforcement for oh-my-posh installer
# Uses existing installed binary to obtain expected hash and performs reinstall via local file path.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$DOTFILES_DIR/scripts/install-oh-my-posh.sh"

if [[ ! -f "$INSTALLER" ]]; then
  echo "SKIP: installer script missing"
  exit 0
fi

BIN_PATH="$(command -v oh-my-posh)"
if command -v sha256sum >/dev/null 2>&1; then
  HASH="$(sha256sum "$BIN_PATH" | awk '{print $1}')"
else
  HASH="$(shasum -a 256 "$BIN_PATH" | awk '{print $1}')"
fi
TMP_COPY="$(mktemp)"
trap 'rm -f "$TMP_COPY"' EXIT
cp "$BIN_PATH" "$TMP_COPY"
fi
TMP_COPY="$(mktemp)"
trap 'rm -f "$TMP_COPY"' EXIT
cp "$BIN_PATH" "$TMP_COPY"
BIN_PATH="$(command -v oh-my-posh)"
HASH=$(sha256sum "$BIN_PATH" | awk '{print $1}')
TMP_COPY=$(mktemp)
cp "$BIN_PATH" "$TMP_COPY"

# Run installer using local file + expected hash (forces reinstall by bumping temp version var)
OMP_VERSION="v24.9.0" OMP_LOCAL_FILE="$TMP_COPY" OMP_EXPECTED_SHA256="$HASH" bash "$INSTALLER" >/dev/null 2>&1 || {
  echo "FAIL: installer failed with valid checksum"; exit 1; }

echo "PASS: checksum verified successfully"
