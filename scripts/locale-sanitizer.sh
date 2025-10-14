#!/usr/bin/env bash
# Locale Sanitizer: Ensures safe UTF-8 fallback for Git Bash, WSL, and Linux
# Purpose: Prevent locale errors like "setlocale: LC_ALL: cannot change locale (en_US.UTF-8)"
# Usage:
#   DRY_RUN=true ./locale-sanitizer.sh   # show what would change
#   ./locale-sanitizer.sh                # apply changes in this shell session

set -euo pipefail

DRY_RUN="${DRY_RUN:-false}"
LOG_TARGET="${LOG_TARGET:-stderr}"

log() {
  if [[ "$LOG_TARGET" == "stderr" ]]; then
    echo "[locale-sanitizer] $*" >&2
  else
    echo "[locale-sanitizer] $*"
  fi
}

apply_locale() {
  local target="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "Would export LC_ALL=$target"
  else
    export LC_ALL="$target"
    log "Applied LC_ALL=$target"
  fi
}

sanitize_locale() {
  # Respect user-defined LC_ALL
  if [[ -n "${LC_ALL:-}" ]]; then
    log "LC_ALL already set to '$LC_ALL', skipping"
    return
  fi

  # Promote LANG if available
  if [[ -n "${LANG:-}" ]]; then
    apply_locale "$LANG"
    return
  fi

  # Detect available fallback
  local fallback=""
  if command -v rg >/dev/null 2>&1 && locale -a 2>/dev/null | rg -q '^C\\.UTF-8$'; then
    fallback="C.UTF-8"
  elif locale -a 2>/dev/null | grep -q '^C\\.UTF-8$'; then
    fallback="C.UTF-8"
  else
    fallback="POSIX"
  fi

  # Optionally set LANG too
  if [[ -z "${LANG:-}" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      log "Would set LANG=$fallback"
    else
      export LANG="$fallback"
      log "Set LANG=$fallback"
    fi
  fi

  apply_locale "$fallback"
}

sanitize_locale
