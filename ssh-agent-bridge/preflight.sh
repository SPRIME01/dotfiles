#!/usr/bin/env bash
# preflight.sh — Sanity checks for WSL bridge + agent + key availability
set -euo pipefail

warn_count=0
fatal=0

echo "== Preflight: Environment =="
echo "WSL Kernel: $(uname -r)"
echo "Distro: $(lsb_release -ds 2>/dev/null || echo N/A)"
echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-<unset>}"

echo
echo "== Check: npiperelay path from manifest =="
WINUSER="$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r' || true)"
if [[ -z "$WINUSER" ]]; then
  echo "Could not determine Windows user" >&2; warn_count=$((warn_count+1))
fi
MANIFEST="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
  echo "Warning: Missing manifest at $MANIFEST — run install-win-ssh-agent.ps1" >&2; warn_count=$((warn_count+1))
  NPIPERELAY=""
else
  echo "Manifest OK: $MANIFEST"
  if command -v jq >/dev/null 2>&1; then
    NPIPERELAY="$(jq -r '.npiperelay_wsl' "$MANIFEST" 2>/dev/null || echo '')"
  else
    NPIPERELAY="$(grep -oE '\"npiperelay_wsl\"\s*:\s*\"[^\"]+\"' "$MANIFEST" | sed -E 's/.*:\"([^\"]+)\"/\\1/')"
  fi
fi

if [[ -z "$NPIPERELAY" || ! -f "$NPIPERELAY" ]]; then
  echo "Warning: Invalid or missing npiperelay path from manifest: '$NPIPERELAY'" >&2; warn_count=$((warn_count+1))
else
  echo "npiperelay: $NPIPERELAY"
fi

echo
echo "== Check: Agent keys visible in WSL =="
if ssh-add -l >/dev/null 2>&1; then
  ssh-add -l
else
  echo "Warning: ssh-add -l failed; the bridge may not be running." >&2; warn_count=$((warn_count+1))
fi

echo
echo "== Check: ~/.ssh/config hosts =="
if [[ -f "$HOME/.ssh/config" ]]; then
  echo "Hosts:"
  awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$HOME/.ssh/config" | tr -s ' ' '\n' | sort -u
else
  echo "No ~/.ssh/config found."
fi

echo
if [[ $fatal -eq 1 ]]; then
  echo "Preflight: FAILED" >&2
  exit 1
elif [[ $warn_count -gt 0 ]]; then
  echo "Preflight: OK (warnings)"
  exit 0
else
  echo "Preflight: OK"
  exit 0
fi
