\
#!/usr/bin/env bash
# full-rotate-and-deploy.sh
# Orchestrates Windows key rotation + WSL deployment in one guided run.
#
# Steps:
#  1) Calls Windows PowerShell: rotate-ed25519.ps1 (with -DryRun if requested)
#  2) Runs WSL bridge installer if desired
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
#
set -euo pipefail

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
    --only) ONLY="$2"; shift ;;
    --exclude) EXCLUDE="$2"; shift ;;
    --jobs|-j) JOBS="$2"; shift ;;
    --timeout) TIMEOUT="$2"; shift ;;
    --resume) RESUME=1 ;;
    --old-keys-dir) OLD_DIR="$2"; shift ;;
    --skip-bridge) SKIP_BRIDGE=1 ;;
    -h|--help) sed -n '1,80p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

run() { [[ $VERBOSE -eq 1 ]] && echo "+ $*" >&2 || true; eval "$@"; }

echo "== Step 1: Rotate ed25519 key in Windows =="
PS_ARGS="-Verbose"
if [[ $DRY_RUN -eq 1 ]]; then PS_ARGS="-DryRun -Verbose"; fi
if [[ $VERBOSE -eq 1 ]]; then echo "powershell.exe -File rotate-ed25519.ps1 $PS_ARGS"; fi
# Try to call the script from the same folder mounted in WSL2; fallback to PATH
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/rotate-ed25519.ps1" ]]; then
  WIN_PATH="$(wslpath -w "$SCRIPT_DIR/rotate-ed25519.ps1")"
  run "powershell.exe -File \"$WIN_PATH\" $PS_ARGS"
else
  echo "rotate-ed25519.ps1 not found co-located; attempting PATH invocation..."
  run "powershell.exe -Command \"rotate-ed25519.ps1 $PS_ARGS\""
fi

echo
if [[ $SKIP_BRIDGE -eq 0 ]]; then
  echo "== Step 2: Ensure WSL bridge is installed =="
  if [[ -f "$SCRIPT_DIR/install-wsl-agent-bridge.sh" ]]; then
    BRIDGE_ARGS="--verbose"
    if [[ $DRY_RUN -eq 1 ]]; then BRIDGE_ARGS="--dry-run --verbose"; fi
    run "bash \"$SCRIPT_DIR/install-wsl-agent-bridge.sh\" $BRIDGE_ARGS"
  else
    echo "install-wsl-agent-bridge.sh not found; skipping bridge install step."
  fi
fi

echo
echo "== Step 3: Deploy to hosts =="
DEPLOY_ARGS="--verbose --jobs $JOBS --timeout $TIMEOUT"
[[ $DRY_RUN -eq 1 ]] && DEPLOY_ARGS="--dry-run $DEPLOY_ARGS"
[[ $RESUME -eq 1 ]] && DEPLOY_ARGS="$DEPLOY_ARGS --resume"
[[ -n "$ONLY" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --only \"$ONLY\""
[[ -n "$EXCLUDE" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --exclude \"$EXCLUDE\""
[[ -n "$OLD_DIR" ]] && DEPLOY_ARGS="$DEPLOY_ARGS --old-keys-dir \"$OLD_DIR\""

if [[ -f "$SCRIPT_DIR/deploy-ssh-key-to-hosts.sh" ]]; then
  run "bash \"$SCRIPT_DIR/deploy-ssh-key-to-hosts.sh\" $DEPLOY_ARGS"
else
  echo "deploy-ssh-key-to-hosts.sh not found in script dir." >&2
  exit 1
fi

echo
echo "All steps completed."
