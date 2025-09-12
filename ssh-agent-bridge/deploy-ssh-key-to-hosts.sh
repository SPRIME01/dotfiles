#!/usr/bin/env bash
# Clean minimal version (dry-run focused) after corruption repair.
set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$COMMON_DIR/common.sh" ]]; then
  # shellcheck disable=SC1091
  source "$COMMON_DIR/common.sh"
fi

DRY_RUN=0 VERBOSE=0 ONLY_PATTERNS="" EXCLUDE_PATTERNS="" JOBS=1 TIMEOUT=5 RESUME=0 OLD_KEYS_DIR="" CONFIRM_CLEANUP=0
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --only) ONLY_PATTERNS="${2:-}"; shift ;;
    --exclude) EXCLUDE_PATTERNS="${2:-}"; shift ;;
    --jobs|-j) JOBS="${2:-1}"; shift ;;
    --timeout) TIMEOUT="${2:-5}"; shift ;;
    --resume) RESUME=1 ;;
    --old-keys-dir) OLD_KEYS_DIR="${2:-}"; shift ;;
    --confirm-cleanup) CONFIRM_CLEANUP=1 ;;
    -h|--help) sed -n '1,120p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

log(){ local ts; ts=$(date -Is); echo "[$ts] [${2:-INFO}] $1"; }
dbg(){ [[ $VERBOSE -eq 1 ]] && log "$*" DEBUG || true; }

ssh_config="$HOME/.ssh/config"
if [[ ! -f "$ssh_config" ]]; then
  if (( DRY_RUN )); then
    log "No ~/.ssh/config found; (dry-run) nothing to do." WARN
    exit 0
  else
    log "No ~/.ssh/config; aborting." ERROR
    exit 1
  fi
fi

mapfile -t all_hosts < <(awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$ssh_config" | sort -u)
filter_hosts(){ local h; for h in "${all_hosts[@]}"; do local inc=1; if [[ -n "$ONLY_PATTERNS" ]]; then inc=0; IFS=',' read -ra pats <<<"$ONLY_PATTERNS"; for p in "${pats[@]}"; do [[ $h == $p ]] && inc=1; done; fi; if [[ $inc -eq 1 && -n "$EXCLUDE_PATTERNS" ]]; then IFS=',' read -ra xp <<<"$EXCLUDE_PATTERNS"; for x in "${xp[@]}"; do [[ $h == $x ]] && inc=0; done; fi; [[ $inc -eq 1 ]] && echo "$h"; done; }
mapfile -t hosts < <(filter_hosts)
if [[ ${#hosts[@]} -eq 0 ]]; then
  if (( DRY_RUN )); then log "Host filter produced no targets. (dry-run) Exiting successfully." WARN; exit 0; else log "Host filter produced no targets." ERROR; exit 1; fi
fi

log "Target hosts (${#hosts[@]}): ${hosts[*]}"

if (( DRY_RUN )); then
  for h in "${hosts[@]}"; do
    log "[DRY-RUN] Would: ssh-copy-id -i <public_key> '$h'"
    log "[DRY-RUN] Would: verify non-interactive login via agent"
    if [[ $CONFIRM_CLEANUP -eq 1 ]]; then
      log "[DRY-RUN] Would: attempt cleanup of old keys (confirm flag present)"
    else
      log "[DRY-RUN] Would: skip cleanup (no --confirm-cleanup)"
    fi
  done
  log "===== SUMMARY ====="
  echo "Hosts processed: ${#hosts[@]}"
  echo "Completed:       ${#hosts[@]}"
  echo "Failures:        0"
  echo "Cleanup: (dry-run only)"
  exit 0
fi

log "Non-dry-run mode not implemented in minimal repair version." ERROR
exit 2
