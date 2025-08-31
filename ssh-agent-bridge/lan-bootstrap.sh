#!/usr/bin/env bash
# lan-bootstrap.sh — Bootstrap LAN SSH trust from WSL using your Windows agent key.
# - Reads hosts from a file (default: hosts.txt), lines like: user@host[:port]
# - Appends your Windows public key to each host's authorized_keys
# - Verifies agent-only login (no password)
# - (Optional) Disables password authentication on the server AFTER key login works
# - Idempotent, resumable, logs to ~/.ssh/logs
#
# Usage examples:
#   bash lan-bootstrap.sh --dry-run
#   bash lan-bootstrap.sh --hosts ./myhosts.txt --jobs 4
#   bash lan-bootstrap.sh --only "prime@192.168.0.50" --disable-password-auth
#   bash lan-bootstrap.sh --resume --jobs 8
#
# Host file format (one per line, comments # allowed):
#   prime@192.168.0.50
#   ubuntu@host2.local
#   root@192.168.0.77:2222
#!/usr/bin/env bash
# lan-bootstrap.sh — Bootstrap LAN SSH trust from WSL/Linux using your agent key.
# - Reads hosts from a file (default: hosts.txt), lines like: user@host[:port]
# - Appends your public key to each host's authorized_keys
# - Verifies agent-only login (no password)
# - (Optional) Disables password authentication on the server AFTER key login works
# - Idempotent, resumable, logs to ~/.ssh/logs
set -euo pipefail

# Script directory (for resolving default hosts file)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Defaults
HOSTS_FILE="${HOSTS_FILE:-$SCRIPT_DIR/hosts.txt}"
DRY_RUN=0
VERBOSE=0
JOBS=4
RESUME=0
ONLY=""
EXCLUDE=""
DISABLE_PW_AUTH=0
TIMEOUT=8

# Detect Windows user (for WSL); allow override via --pubkey
detect_win_user() {
  local u; u="$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r' || true)"
  [[ -z "$u" ]] && u="$(ls -1 /mnt/c/Users 2>/dev/null | head -1 || true)"
  echo "$u"
}
WIN_USER="$(detect_win_user)"
PUBKEY="${PUBKEY:-/mnt/c/Users/${WIN_USER}/.ssh/id_ed25519.pub}"

usage() {
  cat <<'USAGE'
Options:
  --hosts <file>            Path to hosts file (default: ./hosts.txt)
  --pubkey <path>           Path to public key (.pub)
  --jobs, -j <N>            Parallel jobs (default: 4)
  --only "host1,host2"      Process only these hosts (exact match)
  --exclude "host1,..."     Skip these hosts
  --timeout <sec>           SSH connect timeout (default: 8)
  --disable-password-auth   After verify, set PasswordAuthentication no on server
  --resume                  Skip hosts previously marked complete
  --dry-run                 Print actions but do nothing
  --verbose, -v             More logging
  -h, --help                This help
USAGE
}

while (( "$#" )); do
  case "$1" in
    --hosts) HOSTS_FILE="$2"; shift ;;
    --pubkey) PUBKEY="$2"; shift ;;
    --jobs|-j) JOBS="$2"; shift ;;
    --only) ONLY="$2"; shift ;;
    --exclude) EXCLUDE="$2"; shift ;;
    --timeout) TIMEOUT="$2"; shift ;;
    --disable-password-auth) DISABLE_PW_AUTH=1 ;;
    --resume) RESUME=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac; shift
done

# In dry-run, avoid background concurrency for simpler, reliable output
if [[ $DRY_RUN -eq 1 ]]; then
  JOBS=1
fi

# If a relative hosts path was provided and not found, try resolving from script dir
if [[ "$HOSTS_FILE" != /* && ! -f "$HOSTS_FILE" ]]; then
  if [[ -f "$SCRIPT_DIR/$HOSTS_FILE" ]]; then
    HOSTS_FILE="$SCRIPT_DIR/$HOSTS_FILE"
  fi
fi

# Logging & state
LOGDIR="$HOME/.ssh/logs"; mkdir -p "$LOGDIR"
RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOGFILE="$LOGDIR/lan-bootstrap_${RUN_ID}.log"
STATE="$LOGDIR/lan-bootstrap_state.tsv"  # TSV: host<TAB>status<TAB>timestamp
: >"$LOGFILE"
touch "$STATE"

ts(){ date -Is; }
log(){ echo "[$(ts)] [$2] $1" | tee -a "$LOGFILE"; }
info(){ log "$1" "INFO"; }
dbg(){ [[ $VERBOSE -eq 1 ]] && log "$1" "DEBUG" || true; }
warn(){ log "$1" "WARN"; }
err(){ log "$1" "ERROR"; }

state_get(){ awk -F'\t' -v h="$1" '$1==h{st=$2} END{print st}' "$STATE" 2>/dev/null; }
state_set(){
  [[ $DRY_RUN -eq 1 ]] && return 0
  printf "%s\t%s\t%s\n" "$1" "$2" "$(ts)" >> "$STATE"
}

# Guards
[[ -s "$HOSTS_FILE" ]] || { err "Hosts file not found: $HOSTS_FILE"; exit 1; }
if [[ $DRY_RUN -ne 1 ]]; then
  if [[ ! -s "$PUBKEY" ]]; then
    for cand in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub"; do
      [[ -s "$cand" ]] && PUBKEY="$cand" && break
    done
  fi
  [[ -s "$PUBKEY" ]] || { err "Public key not found: $PUBKEY"; exit 1; }
fi

# Load hosts
mapfile -t RAW_HOSTS < <( \
  grep -v '^[[:space:]]*#' "$HOSTS_FILE" | \
  sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | \
  sed '/^$/d' )
filter_hosts(){
  local h; for h in "${RAW_HOSTS[@]}"; do
    local include=1
    if [[ -n "$ONLY" ]]; then
      include=0; IFS=',' read -ra list <<<"$ONLY"
      local x; for x in "${list[@]}"; do [[ "$h" == "$x" ]] && include=1; done
    fi
    if [[ $include -eq 1 && -n "$EXCLUDE" ]]; then
      IFS=',' read -ra xlist <<<"$EXCLUDE"
      local x; for x in "${xlist[@]}"; do [[ "$h" == "$x" ]] && include=0; done
    fi
    [[ $include -eq 1 ]] && echo "$h"
  done
}
mapfile -t HOSTS < <(filter_hosts)
[[ ${#HOSTS[@]} -gt 0 ]] || { err "No hosts to process after filtering."; exit 1; }

info "Using public key: $PUBKEY"
info "Target hosts (${#HOSTS[@]}): ${HOSTS[*]}"
[[ $DRY_RUN -eq 1 ]] && info "DRY-RUN mode — no changes or network calls."

# Helpers
run(){
  dbg "+ $*"
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "DRY-RUN: $*"
    return 0
  fi
  eval "$@"
}
host_parts(){ # input user@host[:port] -> prints "user host port"
  local s="$1" user host port
  user="${s%@*}"; host="${s#*@}"
  if [[ "$host" == *:* ]]; then port="${host##*:}"; host="${host%%:*}"; else port=""; fi
  echo "$user" "$host" "$port"
}

append_key(){ # $1=user@host[:port]
  local s="$1"; read -r user host port < <(host_parts "$s")
  local port_opt=""; [[ -n "$port" ]] && port_opt="-p $port"
  if command -v ssh-copy-id >/dev/null 2>&1; then
    if run "ssh-copy-id -F /dev/null -o ConnectTimeout=$TIMEOUT $port_opt -i \"$PUBKEY\" \"$user@$host\" >>\"$LOGFILE\" 2>&1"; then
      return 0
    else
      warn "ssh-copy-id failed on $host; attempting portable fallback"
    fi
  fi
  # Portable fallback: try POSIX sh, then PowerShell on Windows, finally no-op to keep exit 0 if connection succeeded
  run "cat \"$PUBKEY\" | ssh -F /dev/null -o ConnectTimeout=$TIMEOUT $port_opt \"$user@$host\" \"sh -c 'set -e; umask 077; D=\"$HOME/.ssh\"; F=\"$D/authorized_keys\"; mkdir -p \"$D\"; touch \"$F\"; chmod 700 \"$D\"; chmod 600 \"$F\"; IFS= read -r key; grep -qxF \"$key\" \"$F\" || echo \"$key\" >> \"$F\"'\" 2>nul || powershell -NoProfile -Command \"$d = Join-Path $env:USERPROFILE \\\".ssh\\\"; New-Item -ItemType Directory -Force -Path $d | Out-Null; $f = Join-Path $d \\\"authorized_keys\\\"; if (-not (Test-Path $f)) { New-Item -ItemType File -Path $f | Out-Null }; $key = [Console]::In.ReadLine(); if (-not (Select-String -Path $f -SimpleMatch -Quiet -Pattern $key)) { Add-Content -Path $f -Value $key }\" || cmd.exe /c type nul >nul >>\"$LOGFILE\" 2>&1"
}

verify_key(){ # $1=user@host[:port]
  local s="$1"; read -r user host port < <(host_parts "$s")
  local port_opt=""; [[ -n "$port" ]] && port_opt="-p $port"
  # Use a shell-agnostic command that returns 0 on Linux and Windows OpenSSH
  run "ssh -F /dev/null -o BatchMode=yes -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o ConnectTimeout=$TIMEOUT $port_opt $user@$host echo OK >>\"$LOGFILE\" 2>&1"
}

disable_password_auth(){ # $1=user@host[:port]
  local s="$1"; read -r user host port < <(host_parts "$s")
  local port_opt=""; [[ -n "$port" ]] && port_opt="-p $port"
  local remote='
set -e
SSHD=/etc/ssh/sshd_config
if [ ! -f "$SSHD" ]; then echo "No $SSHD on server"; exit 0; fi
cp "$SSHD" "$SSHD.bak_$(date +%Y%m%d%H%M%S)"
sed -i -E "s/^[#[:space:]]*PasswordAuthentication[[:space:]].*/PasswordAuthentication no/i" "$SSHD" || true
grep -qE "^[#[:space:]]*PasswordAuthentication[[:space:]]+no" "$SSHD" || echo "PasswordAuthentication no" >> "$SSHD"
sed -i -E "s/^[#[:space:]]*PubkeyAuthentication[[:space:]].*/PubkeyAuthentication yes/i" "$SSHD" || true
grep -qE "^[#[:space:]]*PubkeyAuthentication[[:space:]]+yes" "$SSHD" || echo "PubkeyAuthentication yes" >> "$SSHD"
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl reload sshd 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || sudo systemctl restart ssh 2>/dev/null || true
else
  sudo service ssh reload 2>/dev/null || sudo service ssh restart 2>/dev/null || sudo /etc/init.d/ssh restart 2>/dev/null || true
fi'
  run "ssh -F /dev/null -o ConnectTimeout=$TIMEOUT $port_opt $user@$host \"$remote\" >>\"$LOGFILE\" 2>&1"
}

process_host(){ # $1=user@host[:port]
  local H="$1"
  info "---- Host: $H ----"
  if [[ $RESUME -eq 1 ]]; then
    local st; st="$(state_get "$H")"
    if [[ "${st:-}" == "complete" ]]; then
      info "Skip (resume): $H"; return 0
    fi
  fi
  if ! append_key "$H"; then
    err "ssh-copy-id/manual append failed for $H"; state_set "$H" "failed_push"; return 1
  fi
  info "[+] Key appended on $H"
  if ! verify_key "$H"; then
    err "Verification failed (publickey) on $H"; state_set "$H" "failed_verify"; return 1
  fi
  info "[+] Verified agent login on $H"
  if [[ $DISABLE_PW_AUTH -eq 1 ]]; then
    if ! disable_password_auth "$H"; then
      err "Failed to disable password auth on $H"; state_set "$H" "failed_harden"; return 1
    fi
    info "[+] PasswordAuthentication disabled on $H"
  fi
  state_set "$H" "complete"
  info "[✓] Completed $H"
}

# Runner
if ! [[ "$JOBS" =~ ^[0-9]+$ ]]; then JOBS=1; fi
(( JOBS < 1 )) && JOBS=1
pids=(); active=0; failures=0
for h in "${HOSTS[@]}"; do
  if (( JOBS > 1 )); then
    ( process_host "$h" ) & pids+=($!); ((active++))
    if (( active >= JOBS )); then
      if wait -n 2>/dev/null; then :; else
        wait "${pids[0]}" || failures=1
        pids=("${pids[@]:1}")
      fi
      ((active--))
    fi
  else
    process_host "$h" || failures=1
  fi
done
for pid in "${pids[@]}"; do wait "$pid" || failures=1; done

echo
info "===== SUMMARY ====="
total="${#HOSTS[@]}"
if [[ $DRY_RUN -eq 1 ]]; then
  done_count="$total"
  failed_count=0
else
  done_count=$(awk '$2=="complete"{c++} END{print c+0}' "$STATE")
  failed_count=$(awk '$2 ~ /^failed_/{c++} END{print c+0}' "$STATE")
fi
echo "Log:       $LOGFILE"
echo "State:     $STATE"
echo "Processed: $total"
echo "Completed: $done_count"
echo "Failures:  $failed_count"
exit $failures
    fi
