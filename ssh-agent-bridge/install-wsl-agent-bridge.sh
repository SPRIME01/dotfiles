#!/usr/bin/env bash
# =====================================================================
# install-wsl-agent-bridge.sh
# Idempotent WSL2→Windows ssh-agent bridge via npiperelay + socat.
# - Reads Windows manifest at /mnt/c/Users/<You>/.ssh/bridge-manifest.json
# - Installs socat if needed
# - Creates ~/.local/bin/win-ssh-agent-bridge
# - Replaces (not appends) a BEGIN/END block in ~/.bashrc and ~/.zshrc
# - Dry-run + verbose logging + manifest
# =====================================================================

set -euo pipefail

DRY_RUN=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --verbose) VERBOSE=1 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

logdir="$HOME/.ssh/logs"; mkdir -p "$logdir"
logfile="$logdir/wsl-agent-bridge_$(date +%Y%m%d_%H%M%S).log"

log() {
  local lvl="${2:-INFO}"
  local ts; ts=$(date -Is)
  echo "[$ts] [$lvl] $*" | tee -a "$logfile" >/dev/null
}
run() {
  [[ $VERBOSE -eq 1 ]] && log "+ $*" "DEBUG"
  if [[ $DRY_RUN -eq 1 ]]; then log "DRY-RUN (skip): $*" "WARN"; else eval "$@"; fi
}

write_file() { # usage: write_file <path> then provide stdin
  local path="$1"; shift || true
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY-RUN (skip write): $path" "WARN"
    cat > /dev/null
  else
    cat > "$path"
  fi
}

log "===== BEGIN WSL Bridge Install ====="
log "DryRun=$DRY_RUN Verbose=$VERBOSE  Kernel=$(uname -r)"

# 1) Locate Windows manifest
WINUSER="$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r' || true)"
if [[ -z "$WINUSER" ]]; then WINUSER="$(ls -1 /mnt/c/Users 2>/dev/null | head -n1 || true)"; fi
[[ -z "$WINUSER" ]] && { log "Cannot determine Windows user." "ERROR"; exit 1; }

MANIFEST="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
  log "Windows manifest not found at $MANIFEST. Run install-win-ssh-agent.ps1 first." "ERROR"
  exit 1
fi

# Prefer jq for robust parsing; fallback to grep/sed if missing
if command -v jq >/dev/null 2>&1; then
  NPIPERELAY="$(jq -r '.npiperelay_wsl' "$MANIFEST" 2>/dev/null || echo '')"
else
  NPIPERELAY="$(grep -oE '"npiperelay_wsl"\s*:\s*"[^"]+"' "$MANIFEST" | sed -E 's/.*:"([^"]+)"/\1/')"
fi

# Fallback chain: npiperelay_wsl -> npiperelay_path -> npiperelay_win (converted)
if [[ -z "$NPIPERELAY" || ! -f "$NPIPERELAY" ]]; then
  if command -v jq >/dev/null 2>&1; then
    alt_path="$(jq -r '.npiperelay_path' "$MANIFEST" 2>/dev/null || echo '')"
    alt_win="$(jq -r '.npiperelay_win'  "$MANIFEST" 2>/dev/null || echo '')"
  else
    alt_path="$(grep -oE '"npiperelay_path"\s*:\s*"[^"]+"' "$MANIFEST" | sed -E 's/.*:"([^"]+)"/\1/')"
    alt_win="$(grep -oE '"npiperelay_win"\s*:\s*"[^"]+"'  "$MANIFEST" | sed -E 's/.*:"([^"]+)"/\1/')"
  fi
  for candidate in "$alt_path" "$alt_win"; do
    [[ -z "$candidate" ]] && continue
    if [[ -f "$candidate" ]]; then NPIPERELAY="$candidate"; break; fi
    if [[ "$candidate" =~ ^[A-Za-z]:\\\\ ]]; then
      drive=$(printf '%s' "$candidate" | head -c1 | tr 'A-Z' 'a-z')
      rest=${candidate:2}; rest=${rest//\\/\/}
      guess="/mnt/${drive}/${rest}"
      if [[ -f "$guess" ]]; then NPIPERELAY="$guess"; break; fi
    fi
  done
fi

if [[ -z "$NPIPERELAY" || ! -f "$NPIPERELAY" ]]; then
  log "npiperelay path invalid in manifest (npiperelay_wsl + fallback failed)." "ERROR"
  log "Open manifest and verify npiperelay_wsl (or npiperelay_path) points to a valid .exe path mounted in WSL." "ERROR"
  exit 1
fi
log "npiperelay: $NPIPERELAY"

# 2) Ensure socat
if ! command -v socat >/dev/null 2>&1; then
  log "Installing socat..."
  run "sudo apt-get update"
  run "sudo apt-get install -y socat"
else
  log "socat present"
fi

# 3) Bridge launcher
bindir="$HOME/.local/bin"; run "mkdir -p '$bindir'"
bridge="$bindir/win-ssh-agent-bridge"
sock="$HOME/.ssh/agent.sock"
pipe='//./pipe/openssh-ssh-agent'

write_file "$bridge" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${SSH_AUTH_SOCK:="$HOME/.ssh/agent.sock"}"
: "${NPIPERELAY:=""}"
: "${WIN_AGENT_PIPE:='//./pipe/openssh-ssh-agent'}"

if [[ -z "$NPIPERELAY" ]]; then
  echo "NPIPERELAY not set" >&2; exit 1
fi
# If already listening, exit silently (idempotent)
if ss -a 2>/dev/null | grep -q "$SSH_AUTH_SOCK"; then exit 0; fi

rm -f "$SSH_AUTH_SOCK"
# Relay socket <-> Windows named pipe; -ei: exit if other end closes
setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"$NPIPERELAY -ei -s $WIN_AGENT_PIPE",nofork >/dev/null 2>&1 &
EOF
run "chmod +x '$bridge'"

# 4) Replace shell init block (idempotent)
begin="# >>> WSL→Windows SSH agent bridge (BEGIN) >>>"
end="# <<< WSL→Windows SSH agent bridge (END) <<<"
block_content=$(cat <<BLOCK
export WINUSER="$WINUSER"
export NPIPERELAY="$NPIPERELAY"
export SSH_AUTH_SOCK="$sock"
"$bridge" >/dev/null 2>&1 || true
BLOCK
)

replace_block() {
  local file="$1"; touch "$file"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY-RUN: would ensure managed block in $file" "WARN"
    return 0
  fi
  local tmp="$file.tmp"
  awk -v b="$begin" -v e="$end" 'BEGIN{p=1} $0==b{p=0} $0==e{p=1;next} p' "$file" > "$tmp" && mv "$tmp" "$file"
  {
    printf "\n%s\n" "$begin"
    printf "%s\n" "$block_content"
    printf "%s\n" "$end"
  } >>"$file"
  log "Wrote bridge block to $file"
}

replace_block "$HOME/.bashrc"
if [[ -n "${ZDOTDIR:-}" && -d "$ZDOTDIR" ]]; then
  replace_block "$ZDOTDIR/.zshrc"
else
  replace_block "$HOME/.zshrc"
fi

# 5) Immediate activation for current shell
if [[ $DRY_RUN -eq 0 ]]; then
  export NPIPERELAY="$NPIPERELAY" SSH_AUTH_SOCK="$sock"
  "$bridge" >/dev/null 2>&1 || true
else
  log "DRY-RUN: would start bridge process now" "WARN"
fi

# 6) Local manifest
write_file "$HOME/.ssh/bridge-manifest.wsl.json" <<JSON
{
  "version": 1,
  "winuser": "$WINUSER",
  "npiperelay_wsl": "$NPIPERELAY",
  "agent_sock": "$sock",
  "installer": "install-wsl-agent-bridge.sh",
  "updated_at": "$(date -Is)"
}
JSON

log "Verification (post-run expectations):"
log "  Windows:  ssh-add -l   (keys should be listed)"
log "  WSL2:     ssh-add -l   (should match Windows)"
log "  Test:     ssh -T git@github.com"
[[ $DRY_RUN -eq 1 ]] && log "NOTE: Dry-run performed; no rc files or manifest were modified." "INFO"
log "===== COMPLETE WSL Bridge Install ====="
echo "Log: $logfile"
