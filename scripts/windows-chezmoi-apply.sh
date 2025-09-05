#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/windows-chezmoi-apply.sh [SOURCE_DIR]

SRC_DIR=${1:-"${HOME}/dotfiles"}
EXCLUDE_DOCS_PS1=${EXCLUDE_DOCS_PS1:-1}

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
  echo "❌ Run from WSL" >&2
  exit 1
fi

if ! command -v cmd.exe >/dev/null 2>&1; then
  echo "❌ cmd.exe unavailable (WSL interop?)" >&2
  exit 1
fi

WIN_HOME=$(cmd.exe /C "echo %USERPROFILE%" | tr -d '\r')
WIN_HOME_WSL=$(wslpath "$WIN_HOME")

echo "📂 Windows home: $WIN_HOME_WSL"
echo "📦 Source: $SRC_DIR"

EXCLUDES=()
if [[ "$EXCLUDE_DOCS_PS1" == "1" ]]; then
  EXCLUDES+=(--exclude "Documents/PowerShell/Microsoft.PowerShell_profile.ps1")
fi

chezmoi apply --source "$SRC_DIR" --destination "$WIN_HOME_WSL" --verbose "${EXCLUDES[@]}"
