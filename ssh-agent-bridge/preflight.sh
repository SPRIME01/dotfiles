#!/usr/bin/env bash
# preflight.sh - WSL SSH agent bridge diagnostics (clean rewrite)
# Reports PASS/WARN/FAIL for environment, manifest, npiperelay, key, agent, shell init, and hosts.
# Exit codes: 0 (normal even with WARN/FAIL), 1 (if --strict and any FAIL), 2 (usage/arg error).

set -u  # no -e so one failing check won't abort entire run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)"
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
  # shellcheck disable=SC1091
  set +e
  source "$SCRIPT_DIR/common.sh"
  set +e
fi

VERBOSE=0
STRICT=0
QUICK=0
JSON=0
SUMMARY_ONLY=0
COLOR_AUTO=1
FORCE_COLOR=0
for arg in "$@"; do
  case "$arg" in
    --verbose|-v) VERBOSE=1 ;;
    --strict) STRICT=1 ;;
    --quick) QUICK=1 ;;
    --json) JSON=1 ;;
    --summary-only) SUMMARY_ONLY=1 ;;
    --no-color) COLOR_AUTO=0 ;;
    --color) FORCE_COLOR=1 ;;
    -h|--help)
      cat <<'HLP'
Usage: preflight.sh [--quick] [--verbose] [--strict] [--json] [--summary-only] [--no-color|--color]
Checks: Environment, Manifest, npiperelay, Public key, Agent socket & keys, Shell init block, Hosts.
--json          emit machine-readable summary + advice
--summary-only  suppress per-section output (still runs checks)
--no-color      disable ANSI colors (default if not a TTY)
--color         force ANSI colors
HLP
      exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ts(){ date -Is; }
log(){ printf '[%s] %s\n' "$(ts)" "$*"; }
dbg(){ [[ $VERBOSE -eq 1 ]] && log "DEBUG: $*" || true; }

PASS=0; WARN=0; FAIL=0; ADVICE=()

# Color handling
if [[ $FORCE_COLOR -eq 1 ]]; then COLOR_AUTO=1; fi
if [[ $COLOR_AUTO -eq 1 && -t 1 ]]; then
  C_RESET='\033[0m'; C_PASS='\033[32m'; C_WARN='\033[33m'; C_FAIL='\033[31m'; C_HEAD='\033[1m';
else
  C_RESET=''; C_PASS=''; C_WARN=''; C_FAIL=''; C_HEAD='';
fi

emit(){
  local lvl="$1"; shift; local msg="$*"; local prefix
  case "$lvl" in
    PASS) prefix="${C_PASS}PASS${C_RESET}"; ((PASS++));;
    WARN) prefix="${C_WARN}Warning${C_RESET}"; ((WARN++));;
    FAIL) prefix="${C_FAIL}FAIL${C_RESET}"; ((FAIL++));;
  esac
  log "${prefix}: $msg"
}
need(){ ADVICE+=("$1"); }
section(){
  [[ $SUMMARY_ONLY -eq 1 ]] && return 0
  echo; log "${C_HEAD}== $* ==${C_RESET}";
}

########################################
# Environment
########################################
section Environment
if [[ -z "${WSL_DISTRO_NAME:-}" ]] && ! grep -qi microsoft /proc/version 2>/dev/null; then
  emit FAIL "Not running inside WSL"
  need "Run inside WSL to use the Windows agent bridge"
else
  emit PASS "WSL detected (${WSL_DISTRO_NAME:-unknown})"
fi

########################################
# Manifest & npiperelay
########################################
section Manifest
manifest=""
if command -v ssh_bridge_manifest_path >/dev/null 2>&1; then
  manifest="$(ssh_bridge_manifest_path || true)"
fi
if [[ -z "$manifest" ]]; then
  emit WARN "Bridge manifest not found"
  need "Run: just ssh-bridge-install-windows"
else
  emit PASS "Manifest present: $manifest"
  if ! command -v jq >/dev/null 2>&1; then
    emit FAIL "jq missing; cannot parse manifest"
    need "Install jq: sudo apt-get update && sudo apt-get install -y jq"
  else
    if command -v resolve_npiperelay_from_manifest >/dev/null 2>&1; then
      npirelay="$(resolve_npiperelay_from_manifest "$manifest" 2>/dev/null || true)"
    else
      # Fallback to minimal jq-only path extraction
      npirelay="$(jq -r '.npiperelay_wsl // .npiperelay_path // .npiperelay_win // empty' "$manifest" 2>/dev/null || true)"
    fi
    if [[ -z "$npirelay" ]]; then
      emit FAIL "npiperelay fields empty (npiperelay_wsl/_path/_win)"
      need "Re-run Windows bridge installer to populate manifest"
    elif [[ ! -f "$npirelay" ]]; then
      emit FAIL "npiperelay missing: $npirelay"
      need "Install npiperelay (Scoop/Choco) then reinstall bridge"
    else
      emit PASS "npiperelay present: $npirelay"
    fi
  fi
fi

########################################
# Public key
########################################
section Public\ key
pub=""
if [[ -n "$manifest" ]] && command -v ssh_bridge_public_key >/dev/null 2>&1; then
  pub="$(ssh_bridge_public_key "$manifest" || true)"
fi
if [[ -z "$pub" ]]; then
  emit WARN "No public key resolved yet"
  need "Generate/rotate key (Windows side or ssh-keygen)"
elif [[ ! -f "$pub" ]]; then
  emit FAIL "Resolved pubkey path missing: $pub"
  need "Regenerate ed25519 key"
else
  bytes=$(wc -c < "$pub" 2>/dev/null || echo 0)
  if (( bytes < 40 )); then
    emit FAIL "Public key too small (${bytes} bytes)"
    need "Recreate key (ed25519 recommended)"
  else
    emit PASS "Public key OK: $pub"
  fi
fi

########################################
# Agent / Keys
########################################
section Agent
sock="${SSH_AUTH_SOCK:-}"
if [[ -z "$sock" ]]; then
  emit WARN "SSH_AUTH_SOCK not set"
  need "Open a new shell after install"
elif [[ ! -S "$sock" ]]; then
  emit WARN "SSH_AUTH_SOCK not a socket: $sock"
  need "Remove stale path / restart shell"
else
  emit PASS "Agent socket: $sock"
fi
if ssh-add -l >/dev/null 2>&1; then
  key_count=$(ssh-add -l 2>/dev/null | wc -l | tr -d ' ')
  if (( key_count > 0 )); then
    emit PASS "ssh-add lists $key_count key(s)"
  else
    emit WARN "ssh-add lists 0 keys"
    need "Load / generate a key in Windows agent"
  fi
else
  emit WARN "ssh-add -l failed (bridge not active?)"
  need "Ensure bridge installed both sides"
fi

########################################
# Shell init block
########################################
section Shell\ init
marker='WSL→Windows SSH agent bridge (BEGIN)'
if grep -Fq "$marker" "$HOME/.bashrc" 2>/dev/null || ( [[ -f "$HOME/.zshrc" ]] && grep -Fq "$marker" "$HOME/.zshrc" 2>/dev/null ); then
  emit PASS "Init block present"
else
  emit WARN "Init block missing"
  need "Run: just ssh-bridge-install-wsl"
fi

########################################
# Hosts
########################################
section Hosts
if [[ -f "$HOME/.ssh/config" ]]; then
  mapfile -t host_list < <(awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$HOME/.ssh/config" | sort -u)
  if ((${#host_list[@]}==0)); then
    emit WARN "No Host entries (excluding * )"
    need "Add Host blocks before deploy script"
  else
    emit PASS "Hosts: ${#host_list[@]} (${host_list[*]})"
  fi
else
  emit WARN "No ~/.ssh/config (deployment optional)"
fi

########################################
# Summary
########################################
echo
log "Summary: PASS=$PASS WARN=$WARN FAIL=$FAIL" 
if (( ${#ADVICE[@]} > 0 )); then
  [[ $SUMMARY_ONLY -eq 1 ]] && echo
  log "Next Steps:"
  printf '  - %s\n' "${ADVICE[@]}" | awk '!seen[$0]++'
fi

if (( JSON == 1 )); then
  # Build JSON safely (minimal escaping for quotes/backslashes)
  esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
  printf '{"pass":%d,"warn":%d,"fail":%d,"strict":%d,"advice":[' "$PASS" "$WARN" "$FAIL" "$STRICT"
  if ((${#ADVICE[@]})); then
    for i in "${!ADVICE[@]}"; do
      printf '"%s"' "$(esc "${ADVICE[$i]}")"
      if (( i < ${#ADVICE[@]}-1 )); then printf ','; fi
    done
  fi
  printf ']}\n'
fi

if (( FAIL > 0 )) && (( STRICT == 1 )); then
  exit 1
fi
exit 0
