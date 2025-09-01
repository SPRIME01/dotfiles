#!/usr/bin/env bash
# full-rotate-and-deploy.sh
# Orchestrates Windows key rotation + WSL deployment in one guided run.
#
# Steps:
#  1) Calls Windows PowerShell: rotate-ed25519.ps1 (with -DryRun if requested)
#  2) Runs WSL bridge installer if desired
#  2b) Ensures Windows manifest exists (installs if missing)
#  3) Runs deploy-ssh-key-to-hosts.sh with your filters/settings
#
# Flags (pass-through where sensible):
#   --dry-run           Dry-run both rotation and deploy
#   --verbose|-v        Verbose logs
#   --only PATTERNS     Only these hosts (comma-separated globs)
#   --exclude PATTERNS  Exclude these hosts (comma-separated globs)
#   --jobs N            Parallelism
#   --timeout N         Per-host timeout
#   --resume            Resume deploy (skip completed)
#   --old-keys-dir DIR  Explicit backup dir to use for old keys
#   --skip-bridge       Don’t run the WSL bridge installer

set -euo pipefail

# Environment probes
IN_WSL=0
[[ -n "${WSL_DISTRO_NAME:-}" ]] && IN_WSL=1
HAS_POWERSHELL=0
command -v powershell.exe >/dev/null 2>&1 && HAS_POWERSHELL=1

DRY_RUN=0
VERBOSE=0
ONLY=""
EXCLUDE=""
JOBS=4
TIMEOUT=8
RESUME=0
OLD_DIR=""
SKIP_BRIDGE=0

while (( "$#" )); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --only) ONLY="${2:-}"; shift ;;
    --exclude) EXCLUDE="${2:-}"; shift ;;
    --jobs|-j) JOBS="${2:-4}"; shift ;;
    --timeout) TIMEOUT="${2:-8}"; shift ;;
    --resume) RESUME=1 ;;
    --old-keys-dir) OLD_DIR="${2:-}"; shift ;;
    --skip-bridge) SKIP_BRIDGE=1 ;;
    -h|--help) sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

run() { [[ $VERBOSE -eq 1 ]] && echo "+ $*" >&2 || true; eval "$@"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== Step 1: Rotate ed25519 key in Windows =="
PS_ARGS="-Verbose"
[[ $DRY_RUN -eq 1 ]] && PS_ARGS="-DryRun -Verbose"

# If we're in dry-run and powershell.exe isn't available (e.g., not in WSL), skip gracefully
if [[ $DRY_RUN -eq 1 && $HAS_POWERSHELL -eq 0 ]]; then
  echo "(dry-run) Skipping Windows rotation: powershell.exe not available in this environment."
else
  if [[ $HAS_POWERSHELL -eq 0 ]]; then
    echo "ERROR: powershell.exe not found. This step requires WSL + Windows." >&2
    exit 1
  fi
  if [[ -f "$SCRIPT_DIR/rotate-ed25519.ps1" ]]; then
    LINUX_PATH="$SCRIPT_DIR/rotate-ed25519.ps1"
    # Robust approach: always stage to Windows %TEMP% and execute from there
    B64_CONTENT="$(base64 -w0 "$LINUX_PATH")"
    TS="$(date +%Y%m%d%H%M%S)"; TMPNAME="rotate-ed25519_${TS}.ps1"
    TMP_WIN_PATH=$(powershell.exe -NoProfile -NonInteractive -Command '$b64='"'$B64_CONTENT'"'; $tmp=Join-Path $env:TEMP '"'$TMPNAME'"'; [IO.File]::WriteAllBytes($tmp,[Convert]::FromBase64String($b64)); Write-Output $tmp' 2>/dev/null | tr -d '\r' | tail -n1)
    if [[ -z "$TMP_WIN_PATH" ]]; then
      echo "ERROR: Failed to stage temporary script in Windows %TEMP%." >&2
      exit 1
    fi
    run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$TMP_WIN_PATH\" $PS_ARGS"
  else
    echo "rotate-ed25519.ps1 not found co-located; attempting PATH invocation..."
    run "powershell.exe -NoProfile -NonInteractive -Command \"rotate-ed25519.ps1 $PS_ARGS\""
  fi
fi

echo
if [[ $SKIP_BRIDGE -eq 0 ]]; then
  echo "== Step 2: Ensure WSL bridge is installed =="
  # If not in WSL and we're dry-run, skip this step gracefully
  if [[ $DRY_RUN -eq 1 && $IN_WSL -eq 0 ]]; then
    echo "(dry-run) Skipping WSL bridge install: not running inside WSL."
  elif [[ -f "$SCRIPT_DIR/install-wsl-agent-bridge.sh" ]]; then
    BRIDGE_ARGS="--verbose"
    [[ $DRY_RUN -eq 1 ]] && BRIDGE_ARGS="--dry-run --verbose"
    run "bash \"$SCRIPT_DIR/install-wsl-agent-bridge.sh\" $BRIDGE_ARGS"
  else
    echo "install-wsl-agent-bridge.sh not found; skipping bridge install step."
  fi
fi

echo
echo "== Step 2b: Ensure Windows manifest exists =="
SKIP_DEPLOY=0
# Determine expected manifest path in WSL view
WINUSER=""
if [[ $HAS_POWERSHELL -eq 1 ]]; then
  # Use single quotes so Bash doesn't expand $env
  WINUSER=$(powershell.exe -NoProfile -NonInteractive -Command '$env:UserName' 2>/dev/null | tr -d '\r' | tail -n1 || true)
fi
if [[ -z "$WINUSER" ]]; then
  # Prefer a matching Linux $USER if present on Windows
  if [[ -d "/mnt/c/Users/$USER" ]]; then
    WINUSER="$USER"
  else
    # Choose first plausible user directory
    while IFS= read -r d; do
      case "$d" in
        "All Users"|"Default"|"Default User"|"Public"|"WDAGUtilityAccount") continue;;
      esac
      if [[ -d "/mnt/c/Users/$d" ]]; then WINUSER="$d"; break; fi
    done < <(ls -1 /mnt/c/Users 2>/dev/null)
  fi
fi
MANIFEST_WSL="/mnt/c/Users/${WINUSER}/.ssh/bridge-manifest.json"
if [[ ! -f "$MANIFEST_WSL" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "(dry-run) Manifest not found at $MANIFEST_WSL; would run Windows installer to create it."
  else
    echo "Manifest not found at $MANIFEST_WSL — attempting Windows install of ssh-agent manifest..."
    if [[ -f "$SCRIPT_DIR/install-win-ssh-agent.ps1" ]]; then
      LINUX_PATH="$SCRIPT_DIR/install-win-ssh-agent.ps1"
      CAND1="$(wslpath -w "$LINUX_PATH" 2>/dev/null || true)"
      CAND2="${CAND1/\\\\wsl.localhost/\\\\wsl\$}"
      SUBPATH="${LINUX_PATH#/}"; SUBPATH="${SUBPATH//\//\\}"; DISTRO="${WSL_DISTRO_NAME:-}"
      CAND3="\\\\wsl.localhost\\${DISTRO}\\${SUBPATH}"; CAND4="\\\\wsl\$\\${DISTRO}\\${SUBPATH}"
      CANDIDATES=(); [[ -n "$CAND1" ]] && CANDIDATES+=("$CAND1"); [[ -n "$CAND2" && "$CAND2" != "$CAND1" ]] && CANDIDATES+=("$CAND2"); [[ -n "$DISTRO" ]] && CANDIDATES+=("$CAND3" "$CAND4")
      FOUND=""
      for p in "${CANDIDATES[@]}"; do
        [[ -z "$p" ]] && continue
        PS_P=$(printf "%s" "$p" | sed "s/'/''/g")
        TP_OUT=$(powershell.exe -NoProfile -NonInteractive -Command "[bool](Test-Path '$PS_P')" 2>/dev/null | tr -d '\r' | tail -n1 || true)
        if [[ "$TP_OUT" =~ ^[Tt]rue$ ]]; then FOUND="$p"; break; fi
      done
      if [[ -n "$FOUND" ]]; then
        run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$FOUND\" -Verbose"
      else
        # Stage to %TEMP%
        B64_CONTENT="$(base64 -w0 "$LINUX_PATH")"; TS="$(date +%Y%m%d%H%M%S)"; TMPNAME="install-win-ssh-agent_${TS}.ps1"
        TMP_WIN_PATH=$(powershell.exe -NoProfile -NonInteractive -Command '$b64='"'$B64_CONTENT'"'; $tmp=Join-Path $env:TEMP '"'$TMPNAME'"'; [IO.File]::WriteAllBytes($tmp,[Convert]::FromBase64String($b64)); Write-Output $tmp' 2>/dev/null | tr -d '\r' | tail -n1)
        if [[ -n "$TMP_WIN_PATH" ]]; then
          run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$TMP_WIN_PATH\" -Verbose"
        else
          echo "WARNING: Could not stage Windows installer script; manifest may remain missing." >&2
        fi
      fi
    else
      echo "Installer script install-win-ssh-agent.ps1 not found; skipping Windows install attempt."
    fi
  fi
fi

# If no hosts configured, skip deploy
SSH_CFG="$HOME/.ssh/config"
if [[ ! -f "$SSH_CFG" ]] || ! awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$SSH_CFG" | grep -q .; then
  echo "No hosts found in ~/.ssh/config; skipping deploy."
  SKIP_DEPLOY=1
fi

echo
echo "== Step 3: Deploy to hosts =="
DEPLOY_ARGS="--verbose --jobs $JOBS --timeout $TIMEOUT"
[[ $DRY_RUN -eq 1 ]] && DEPLOY_ARGS="--dry-run $DEPLOY_ARGS"
[[ -n "$ONLY" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --only \"$ONLY\""
[[ -n "$EXCLUDE" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --exclude \"$EXCLUDE\""
[[ -n "$OLD_DIR" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --old-keys-dir \"$OLD_DIR\""

# If not in WSL and we're dry-run, skip deploy gracefully
if [[ $DRY_RUN -eq 1 && $IN_WSL -eq 0 ]]; then
  echo "(dry-run) Skipping deploy: not running inside WSL."
elif [[ $SKIP_DEPLOY -eq 1 ]]; then
  echo "Skipping deploy due to missing prerequisites."
else
  if [[ -f "$SCRIPT_DIR/deploy-ssh-key-to-hosts.sh" ]]; then
    run "bash \"$SCRIPT_DIR/deploy-ssh-key-to-hosts.sh\" $DEPLOY_ARGS"
  else
    echo "deploy-ssh-key-to-hosts.sh not found in script dir." >&2
    exit 1
  fi
fi

echo
echo "All steps completed."
