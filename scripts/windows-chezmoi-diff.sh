#!/usr/bin/env bash
set -euo pipefail

SRC="${SRC:-$HOME/dotfiles}"
DEST="${DEST:-}"

# If DEST not set, try to discover Windows UserProfile via powershell.exe (WSL interop)
if [[ -z "$DEST" ]]; then
    if command -v powershell.exe >/dev/null 2>&1; then
        winpath=$(powershell.exe -NoProfile -Command '$env:USERPROFILE' 2>/dev/null | tr -d '\r' || true)
        if [[ -n "$winpath" ]]; then
            # Convert C:\Users\Name to /mnt/c/Users/Name (wslpath if available)
            if command -v wslpath >/dev/null 2>&1; then
                DEST="$(wslpath -a "$winpath")"
            else
                DEST="$winpath"
            fi
        fi
    fi
fi

if [[ -z "$DEST" ]]; then
    echo "ERROR: Destination not set. Provide DEST=/mnt/c/Users/You or run from WSL with powershell.exe available." >&2
    exit 2
fi

CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff --source "$SRC" --destination "$DEST" --verbose
fi

CHEZMOI_NO_PAGER=1 PAGER=cat \
  chezmoi diff --source "$SRC_DIR" --destination "$WIN_HOME_WSL" --verbose "${EXCLUDES[@]}"
