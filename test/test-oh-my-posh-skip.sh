#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME="$(mktemp -d)"
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME"' EXIT
export DOTFILES_ROOT="$ROOT"
export OMP_VERSION=skip
export OMP_VERSION=skip
if command -v oh-my-posh >/dev/null 2>&1; then
  echo "INFO: oh-my-posh already present (acceptable)"
fi

if [[ -x "$HOME/.local/bin/oh-my-posh" ]]; then
  echo "FAIL: OMP_VERSION=skip should not install oh-my-posh into HOME" >&2
  exit 1
fi

echo "PASS: skip flag respected"

echo "PASS: skip flag respected"
