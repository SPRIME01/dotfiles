#!/usr/bin/env bash
# cleanup-old-keys.sh — Safely remove old public keys from many hosts.
# - Reads hosts from a file (default: ./hosts.txt), lines like user@host[:port]
# - Requires --old-keys-dir pointing to a folder with *.pub (e.g., /mnt/c/Users/you/.ssh/backup-YYYYMMDDHHMMSS)
# - Verifies agent-only login first; then prunes only exact matching key blobs
# - Per-host authorized_keys backup: authorized_keys.bak_<timestamp>
# - Idempotent, resumable, logs to ~/.ssh/logs

set -euo pipefail

# Load shared helpers if present
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$COMMON_DIR/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$COMMON_DIR/common.sh"
fi

HOSTS_FILE="${HOSTS_FILE:-./hosts.txt}"
OLD_KEYS_DIR=""
DRY_RUN=0
VERBOSE=0
JOBS=4
RESUME=0
TIMEOUT=8
ONLY=""
EXCLUDE=""

usage() {
  cat <<'USAGE'
Options:
  --hosts <file>           Hosts file (default: ./hosts.txt)
  --old-keys-dir <dir>     REQUIRED: directory containing *.pub to remove
  --jobs, -j <N>           Parallel jobs (default: 4)
  --only "<h1,h2>"         Only these hosts (comma-separated shell globs)
  --exclude "<h1,h2>"      Skip these hosts (comma-separated shell globs)
  --timeout <sec>          SSH connect timeout (default: 8)
  --resume                 Skip hosts already marked complete
  --dry-run                Show actions but do nothing
  --verbose, -v            More logging
  -h, --help               This help
USAGE
}

while (( "$#" )); do
  case "$1" in
    --hosts) HOSTS_FILE="$2"; shift ;;
    --old-keys-dir) OLD_KEYS_DIR="$2"; shift ;;
    --jobs|-j) JOBS="$2"; shift ;;
    --only) ONLY="$2"; shift ;;
    --exclude) EXCLUDE="$2"; shift ;;
    --timeout) TIMEOUT="$2"; shift ;;
    --resume) RESUME=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac; shift
done

[[ -n "$OLD_KEYS_DIR" && -d "$OLD_KEYS_DIR" ]] || { echo "ERROR: --old-keys-dir is required and must exist." >&2; exit 1; }
[[ -s "$HOSTS_FILE" ]] || { echo "ERROR: hosts file not found: $HOSTS_FILE" >&2; exit 1; }

LOGDIR="$HOME/.ssh/logs"; mkdir -p "$LOGDIR"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOGFILE="$LOGDIR/cleanup-old-keys_${RUN_ID}.log"
STATE="$LOGDIR/cleanup-old-keys_state.tsv"  # host<TAB>status<TAB>timestamp
touch "$STATE"

ts(){ date -Is; }
log(){ echo "[$(ts)] [$2] $1" | tee -a "$LOGFILE" >/dev/null; }
info(){ log "$1" "INFO"; }
dbg(){ [[ $VERBOSE -eq 1 ]] && log "$1" "DEBUG" || true; }
warn(){ log "$1" "WARN"; }
err(){ log "$1" "ERROR"; }
state_get(){ awk -F'\t' -v h="$1" '$1==h{st=$2} END{print st}' "$STATE" 2>/dev/null; }
state_set(){ printf "%s\t%s\t%s\n" "$1" "$2" "$(ts)" >> "$STATE"; }

# Load hosts
mapfile -t RAW_HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | sed -E 's/^\s+|\s+$//g' | sed '/^$/d')
filter_hosts() {
  local h; for h in "${RAW_HOSTS[@]}"; do
    local include=1
    if [[ -n "$ONLY" ]]; then
      include=0; IFS=',' read -ra lst <<<"$ONLY"
      for x in "${lst[@]}"; do [[ "$h" == "$x" ]] && include=1; done
    fi
    if [[ $include -eq 1 && -n "$EXCLUDE" ]]; then
      IFS=',' read -ra xlst <<<"$EXCLUDE"
      for x in "${xlst[@]}"; do [[ "$h" == "$x" ]] && include=0; done
    fi
    [[ $include -eq 1 ]] && echo "$h"
  done
}
mapfile -t HOSTS < <(filter_hosts)
[[ ${#HOSTS[@]} -gt 0 ]] || { err "No hosts to process after filtering."; exit 1; }

# Collect old key blobs (type + base64 blob)
mapfile -t OLD_BLOBS < <(awk '{if(NF>=2){print $1" "$2}}' "$OLD_KEYS_DIR"/*.pub 2>/dev/null | sed '/^$/d' | sort -u)
[[ ${#OLD_BLOBS[@]} -gt 0 ]] || { err "No *.pub files found in $OLD_KEYS_DIR"; exit 1; }
info "Will remove ${#OLD_BLOBS[@]} old key(s) that exactly match blobs from: $OLD_KEYS_DIR"

host_parts(){ # user@host[:port] -> "user host port"
  local s="$1" user host port
  user="${s%@*}"; host="${s#*@}"
  if [[ "$host" == *:* ]]; then port="${host##*:}"; host="${host%%:*}"; else port=""; fi
  echo "$user" "$host" "$port"
}

verify_key(){ # $1 user@host[:port]
  local s="$1"; read -r user host port < <(host_parts "$s"); local port_opt=""
  [[ -n "$port" ]] && port_opt="-p $port"
  if [[ $DRY_RUN -eq 1 ]]; then
    info "[DRY-RUN] Skipping verify on $s"
    return 0
  fi
  ssh -F /dev/null -o BatchMode=yes \
      -o PreferredAuthentications=publickey \
      -o PasswordAuthentication=no \
      -o ConnectTimeout="$TIMEOUT" \
      $port_opt "$user@$host" \
      "sh -c ':' 2>nul || powershell -NoProfile -Command exit 0 || cmd.exe /c exit 0" \
      >>"$LOGFILE" 2>&1
}

cleanup_host(){ # $1 user@host[:port]
  local H="$1"
  info "---- Host: $H ----"

  if [[ $RESUME -eq 1 ]]; then
    local st; st="$(state_get "$H")"
    if [[ "$st" == "complete" ]]; then
      info "Skip (resume): $H"
      return 0
    fi
  fi

  # Verify we can log in with current key (safety)
  if ! verify_key "$H"; then
    err "Agent login verification failed on $H — not touching authorized_keys"
    state_set "$H" "failed_verify"
    return 1
  fi
  info "[+] Verified agent login on $H"

  if [[ $DRY_RUN -eq 1 ]]; then
    info "[DRY-RUN] Would back up and remove ${#OLD_BLOBS[@]} old key(s) on $H"
    state_set "$H" "dryrun_ok"
    return 0
  fi

  # Build remote script: backup then prune exact blobs
  local remote="set -e
D=\"\$HOME/.ssh\"
F=\"\$D/authorized_keys\"
umask 077
mkdir -p \"\$D\"; touch \"\$F\"
chmod 700 \"\$D\"; chmod 600 \"\$F\"
B=\"\$F.bak_${RUN_ID}\"
cp \"\$F\" \"\$B\"
T=\"\$F.new_${RUN_ID}\"
cp \"\$F\" \"\$T\"
"
  local k
  for k in "${OLD_BLOBS[@]}"; do
    # single-quote-safe
    local ek="${k//\'/\'\"\'\"\'}"
    remote+=$'\n'"grep -vF '$ek' \"\$T\" > \"\$T.f\" && mv \"\$T.f\" \"\$T\""
  done
  remote+=$'\n''mv "$T" "$F"'

  local s="$H"; read -r user host port < <(host_parts "$s"); local port_opt=""
  [[ -n "$port" ]] && port_opt="-p $port"

  if ssh -F /dev/null -o ConnectTimeout="$TIMEOUT" $port_opt "$user@$host" "$remote" >>"$LOGFILE" 2>&1; then
    info "[+] Cleaned old keys on $H (backup: ~/.ssh/authorized_keys.bak_'$RUN_ID')"
    state_set "$H" "complete"
    return 0
  else
    err "Cleanup failed on $H (authorized_keys left intact)"
    state_set "$H" "failed_cleanup"
    return 1
  fi
}

# Runner (no xargs; jobs in same shell)
if ! [[ "$JOBS" =~ ^[0-9]+$ ]]; then JOBS=1; fi
(( JOBS < 1 )) && JOBS=1

pids=(); active=0; failures=0
for h in "${HOSTS[@]}"; do
  if (( JOBS > 1 )); then
    ( cleanup_host "$h" ) & pids+=($!); ((active++))
    if (( active >= JOBS )); then
      if wait -n 2>/dev/null; then :; else
        wait "${pids[0]}" || failures=1
        pids=("${pids[@]:1}")
      fi
      ((active--))
    fi
  else
    cleanup_host "$h" || failures=1
  fi
done
for pid in "${pids[@]}"; do wait "$pid" || failures=1; done

echo
info "===== SUMMARY ====="
total="${#HOSTS[@]}"
done_count=$(awk '$2=="complete"{c++} END{print c+0}' "$STATE")
failed_count=$(awk '$2 ~ /^failed_/{c++} END{print c+0}' "$STATE")
echo "Log:       $LOGFILE"
echo "State:     $STATE"
echo "Processed: $total"
echo "Completed: $done_count"
echo "Failures:  $failed_count"
if [[ $failed_count -gt 0 ]]; then
  echo "Failed hosts (status):"
  awk -F'\t' '$2 ~ /^failed_/{printf " - %s (%s)\n", $1,$2}' "$STATE" | sort -u
fi
exit $failures
