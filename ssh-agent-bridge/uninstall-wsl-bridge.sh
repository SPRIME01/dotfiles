#!/usr/bin/env bash
# uninstall-wsl-bridge.sh — Cleanly remove WSL bridge edits (supports --dry-run, --verbose)
set -euo pipefail

DRY_RUN=0
VERBOSE=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help)
      cat <<'HLP'
Usage: bash uninstall-wsl-bridge.sh [--dry-run] [--verbose]

Removes managed BEGIN/END block from ~/.bashrc and ~/.zshrc, deletes helper binary and socket.
HLP
      exit 0 ;;
    *) echo "Unknown arg: $a" >&2; exit 2 ;;
  esac
done

log(){ local ts; ts=$(date -Is); echo "[$ts] $*"; }
dbg(){ [[ $VERBOSE -eq 1 ]] && log "DEBUG: $*" || true; }
act(){ if [[ $DRY_RUN -eq 1 ]]; then log "DRY-RUN: $*"; else eval "$*"; fi }
begin="# >>> WSL→Windows SSH agent bridge (BEGIN) >>>"
end="# <<< WSL→Windows SSH agent bridge (END) <<<"

clean_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if grep -Fq "$begin" "$file" 2>/dev/null; then
    dbg "Found managed block in $file"
    if [[ $DRY_RUN -eq 1 ]]; then
      log "DRY-RUN: would remove managed block from $file"
    else
      awk -v b="$begin" -v e="$end" 'BEGIN{p=1} $0==b{p=0;next} $0==e{p=1;next} p' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      log "Cleaned: $file"
    fi
  else
    dbg "No managed block in $file"
  fi
}

clean_file "$HOME/.bashrc"
[[ -n "${ZDOTDIR:-}" ]] && clean_file "$ZDOTDIR/.zshrc" || clean_file "$HOME/.zshrc"
if [[ $DRY_RUN -eq 1 ]]; then
  log "DRY-RUN: would remove $HOME/.local/bin/win-ssh-agent-bridge and $HOME/.ssh/agent.sock"
else
  rm -f "$HOME/.local/bin/win-ssh-agent-bridge" "$HOME/.ssh/agent.sock"
fi
log "WSL bridge uninstall ${DRY_RUN:+(dry-run )}complete."
