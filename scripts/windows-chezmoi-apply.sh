#!/usr/bin/env bash
set -euo pipefail

SRC="${SRC:-$HOME/dotfiles}"
DEST="${DEST:-}"

# If DEST not set, try to discover Windows UserProfile via powershell.exe or cmd.exe (WSL interop)
winpath=""
if [[ -z "$DEST" ]]; then
    if command -v powershell.exe >/dev/null 2>&1; then
        winpath=$(powershell.exe -NoProfile -Command '$env:USERPROFILE' 2>/dev/null | tr -d '\r' || true)
    elif command -v cmd.exe >/dev/null 2>&1; then
        winpath=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)
    fi

    if [[ -n "$winpath" ]]; then
        if command -v wslpath >/dev/null 2>&1; then
            DEST="$(wslpath -a "$winpath")"
        else
            DEST="$winpath"
        fi
    fi
fi

if [[ -z "$DEST" ]]; then
    echo "ERROR: Destination not set. Provide DEST=/mnt/c/Users/You or run from WSL with powershell.exe/cmd.exe available." >&2
    exit 2
fi

if ! command -v chezmoi >/dev/null 2>&1; then
    echo "ERROR: 'chezmoi' not found on PATH." >&2
    exit 127
fi

declare -a EXCLUDES=()
EXCLUDES+=(--exclude "Documents/PowerShell/Microsoft.PowerShell_profile.ps1")

# Avoid interactive pager prompts from chezmoi
export CHEZMOI_NO_PAGER=1
export PAGER="${PAGER:-cat}"

chezmoi apply --source "$SRC" --destination "$DEST" --verbose "${EXCLUDES[@]}"
