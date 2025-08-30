#!/usr/bin/env bash
# =====================================================================
# deploy-ssh-key-to-hosts.sh  (v2, single-process, no xargs)
#
# Deploy your Windows-hosted ed25519 PUBLIC key (via WSL bridge) to all
# hosts in ~/.ssh/config, verify non-interactive auth, then *safely*
# remove old keys that match a known-compromised backup.
#
# Features:
# - No subshell scoping bugs (no xargs, no bash -c).
# - Idempotent, resumable (--resume) with a simple state file.
# - Dry-run, verbose logs, filtering (--only/--exclude), parallel jobs.
#
# Usage:
#   bash deploy-ssh-key-to-hosts.sh --dry-run --verbose
#   bash deploy-ssh-key-to-hosts.sh --jobs 8 --only "prod-*,db-*"
# =====================================================================

set -euo pipefail

# -------- CLI --------
DRY_RUN=0
VERBOSE=0
ONLY_PATTERNS=""
EXCLUDE_PATTERNS=""
JOBS=4
TIMEOUT=8
RESUME=0
OLD_KEYS_DIR=""

while (( "$#" )); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --only) ONLY_PATTERNS="${2:-}"; shift ;;
    --exclude) EXCLUDE_PATTERNS="${2:-}"; shift ;;
    --jobs|-j) JOBS="${2:-4}"; shift ;;
    --timeout) TIMEOUT="${2:-8}"; shift ;;
    --resume) RESUME=1 ;;
    --old-keys-dir) OLD_KEYS_DIR="${2:-}"; shift ;;
    -h|--help)
      sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done

# -------- Logging --------
logdir="$HOME/.ssh/logs"; mkdir -p "$logdir"
run_id="$(date +%Y%m%d_%H%M%S)"
logfile="$logdir/deploy-ssh-key_${run_id}.log"
statefile="$logdir/deploy-ssh-key_state.tsv"  # simple TSV: host<TAB>status<TAB>timestamp

log() {
  local lvl="${2:-INFO}"
  local ts; ts=$(date -Is)
  local line="[$ts] [$lvl] $*"
  echo "$line" | tee -a "$logfile" >/dev/null
}
dbg(){ [[ $VERBOSE -eq 1 ]] && log "$*" "DEBUG" || true; }
runeq(){
  dbg "+ $*"
  if [[ $DRY_RUN -eq 1 ]]; then log "DRY-RUN: $*" "WARN"; return 0; fi
  eval "$@"
}

# -------- State (TSV, robust, no Python) --------
touch "$statefile"
state_get() { # $1=host  -> prints status or blank
  awk -v h="$1" -F'\t' '$1==h{print $2}' "$statefile" | tail -n1
}
state_set() { # $1=host $2=status
  local ts; ts="$(date -Is)"
  printf "%s\t%s\t%s\n" "$1" "$2" "$ts" >> "$statefile"
}

# -------- Manifest / public key discovery --------
detect_manifest() {
  local winuser
  winuser="$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r' || true)"
  [[ -z "$winuser" ]] && winuser="$(ls -1 /mnt/c/Users 2>/dev/null | head -n1 || true)"
  [[ -z "$winuser" ]] && { log "Cannot determine Windows user." "ERROR"; exit 1; }
  echo "/mnt/c/Users/${winuser}/.ssh/bridge-manifest.json"
}
to_wsl_path() { # convert C:\foo\bar -> /mnt/c/foo/bar if needed
  local p="$1"
  if [[ "$p" =~ ^[A-Za-z]:\\ ]]; then
    local d="${p:0:1}"; d="${d,,}"
    local t="${p:2}"; t="${t//\\//}"
    echo "/mnt/${d}/${t}"
  else
    echo "$p"
  fi
}
manifest="$(detect_manifest)"
[[ -f "$manifest" ]] || { log "Manifest not found at $manifest. Run install-win-ssh-agent.ps1 first." "ERROR"; exit 1; }

# Try jq, fallback to grep/sed
if command -v jq >/dev/null 2>&1; then
  ssh_key_win="$(jq -r '.ssh_key_path' "$manifest" 2>/dev/null || true)"
else
  ssh_key_win="$(grep -oE '"ssh_key_path"\s*:\s*"[^"]+"' "$manifest" | sed -E 's/.*:\s*"([^"]+)"/\1/')"
fi
ssh_key_wsl="$(to_wsl_path "$ssh_key_win")"
pubkey="${ssh_key_wsl}.pub"
if [[ ! -f "$pubkey" ]]; then
  # Regenerate .pub from private key if missing
  if [[ -f "$ssh_key_wsl" ]]; then
    runeq "ssh-keygen -y -f \"$ssh_key_wsl\" > \"$pubkey\""
  fi
fi
[[ -f "$pubkey" ]] || { log "Public key not found at $pubkey." "ERROR"; exit 1; }
log "Using public key: $pubkey"

# -------- Build host list from ~/.ssh/config --------
ssh_config="$HOME/.ssh/config"
[[ -f "$ssh_config" ]] || { log "No ~/.ssh/config found; nothing to do." "ERROR"; exit 1; }
mapfile -t all_hosts < <(
  awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$ssh_config" \
  | tr -d '\r' \
  | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
  | sort -u
)

# Filters
filter_hosts() {
  local h; for h in "${all_hosts[@]}"; do
    local include=1
    if [[ -n "$ONLY_PATTERNS" ]]; then
      include=0; IFS=',' read -ra pats <<<"$ONLY_PATTERNS"
      for p in "${pats[@]}"; do [[ "$h" == $p ]] && include=1; done
    fi
    if [[ $include -eq 1 && -n "$EXCLUDE_PATTERNS" ]]; then
      IFS=',' read -ra xpats <<<"$EXCLUDE_PATTERNS"
      for xp in "${xpats[@]}"; do [[ "$h" == $xp ]] && include=0; done
    fi
    [[ $include -eq 1 ]] && echo "$h"
  done
}
mapfile -t hosts < <(filter_hosts)
[[ ${#hosts[@]} -gt 0 ]] || { log "Host filter produced no targets." "ERROR"; exit 1; }
log "Target hosts (${#hosts[@]}): ${hosts[*]}"

# -------- Discover old keys to remove (by exact blob match) --------
discover_old_key_blobs() {
  local dir="$1" base keydir
  if [[ -n "$dir" && -d "$dir" ]]; then
    find "$dir" -maxdepth 1 -type f -name '*.pub' -print
    return
  fi
  base="$(dirname "$ssh_key_wsl")" # /mnt/c/Users/<You>/.ssh
  mapfile -t backups < <(ls -1d "$base"/backup-* 2>/dev/null | sort -r)
  [[ ${#backups[@]} -gt 0 ]] && find "${backups[0]}" -maxdepth 1 -type f -name '*.pub' -print
}
mapfile -t old_pub_files < <(discover_old_key_blobs "$OLD_KEYS_DIR" || true)
old_keys=()
for f in "${old_pub_files[@]:-}"; do
  [[ -f "$f" ]] || continue
  k="$(awk '{print $1" "$2}' "$f" | tr -d '\r\n')"
  [[ -n "$k" ]] && old_keys+=("$k")
done
[[ ${#old_keys[@]} -gt 0 ]] && log "Will remove ${#old_keys[@]} old key(s) after verification." || log "No old keys discovered; cleanup will be skipped."

# -------- Per-host worker --------
process_host() {
  local host="$1"
  log "---- Host: $host ----"

  # Dry-run: simulate success and exit early (no state pollution)
  if (( DRY_RUN )); then
    log "[DRY-RUN] Would: ssh-copy-id -i \"$pubkey\" \"$host\""
    log "[DRY-RUN] Would: verify non-interactive login via agent"
    if [[ ${#old_keys[@]} -gt 0 ]]; then
      log "[DRY-RUN] Would: backup authorized_keys and remove ${#old_keys[@]} old key(s)"
    else
      log "[DRY-RUN] Would: skip cleanup (no old keys discovered)"
    fi
    state_set "$host" "dryrun_ok"
    log "[✓] DRY-RUN simulated success for $host"
    return 0
  fi

  # Resume support
  if [[ $RESUME -eq 1 ]]; then
    local s; s="$(state_get "$host")"
    if [[ "$s" == "complete" ]]; then
      log "Skipping $host due to --resume (status=complete)"
      return 0
    fi
  fi

  # 1) Push public key (idempotent)
  if ! runeq "ssh-copy-id -i \"$pubkey\" -o ConnectTimeout=$TIMEOUT \"$host\" >>\"$logfile\" 2>&1"; then
    log "[!] ssh-copy-id failed for $host" "ERROR"
    state_set "$host" "failed_push"
    return 1
  fi
  log "[+] Key copied to $host"

  # 2) Verify non-interactive login using the new key via agent
  if ! ssh -o BatchMode=yes \
          -o PreferredAuthentications=publickey \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o ConnectTimeout="$TIMEOUT" \
          -o StrictHostKeyChecking=accept-new \
          "$host" true >>"$logfile" 2>&1; then
    log "[!] Verification failed for $host — not removing any keys." "ERROR"
    state_set "$host" "failed_verify"
    return 1
  fi
  log "[+] Verified new key for $host"

  # 3) Cleanup: remove ONLY the old exact key blobs (after backup)
  if [[ ${#old_keys[@]} -gt 0 ]]; then
    local rc=0
    local rcmd
    rcmd=$'set -e\numask 077\nD="$HOME/.ssh"\nF="$D/authorized_keys"\nmkdir -p "$D"\ntouch "$F"\nchmod 700 "$D"; chmod 600 "$F"\nB="$F.bak.'"$run_id"$'"\ncp "$F" "$B"\nT="$F.new.'"$run_id"$'"\ncp "$F" "$T"\n'
    for k in "${old_keys[@]}"; do
      ek="${k//\'/\'\"\'\"\'}"
      rcmd+=$'\n'"grep -vF '$ek' \"\$T\" > \"\$T.f\" && mv \"\$T.f\" \"\$T\""
    done
    rcmd+=$'\n''mv "$T" "$F"'
    if ! ssh -o BatchMode=yes -o ConnectTimeout="$TIMEOUT" "$host" "$rcmd" >>"$logfile" 2>&1; then
      log "[!] Cleanup failed on $host (authorized_keys left intact)" "ERROR"
      state_set "$host" "failed_cleanup"
      return 1
    fi
    log "[+] Cleaned old keys on $host (backup kept as authorized_keys.bak.'"$run_id"')"
  else
    log "No old keys known; skipping cleanup on $host"
  fi

  state_set "$host" "complete"
  log "[✓] Completed $host"
}


# -------- Execute over hosts with built-in job control --------
# Ensure numeric jobs
if ! [[ "$JOBS" =~ ^[0-9]+$ ]]; then JOBS=1; fi
(( JOBS < 1 )) && JOBS=1

pids=()
active=0
fail=0

for h in "${hosts[@]}"; do
  if (( JOBS > 1 )); then
    # run in background in the SAME shell (functions in scope)
    ( process_host "$h" ) &
    pids+=($!)
    ((active++))
    if (( active >= JOBS )); then
      if wait -n 2>/dev/null; then :; else
        # Fallback for older bash without wait -n
        wait "${pids[0]}" || fail=1
        pids=("${pids[@]:1}")
      fi
      ((active--))
    fi
  else
    process_host "$h" || fail=1
  fi
done

# wait for the rest
for pid in "${pids[@]}"; do
  wait "$pid" || fail=1
done

echo
log "===== SUMMARY ====="
total="${#hosts[@]}"
done_count=$(awk '$2=="complete"{c++} END{print c+0}' "$statefile")
failed_count=$(awk '$2 ~ /^failed_/{c++} END{print c+0}' "$statefile")
echo "Hosts processed: $total"
echo "Completed:       $done_count"
echo "Failures:        $failed_count"
log "Details in $logfile"

exit $fail
