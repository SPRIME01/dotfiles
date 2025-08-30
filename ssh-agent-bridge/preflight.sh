\
#!/usr/bin/env bash
# preflight.sh — Sanity checks for WSL bridge + agent + key availability
set -euo pipefail

ok=1

echo "== Preflight: Environment =="
echo "WSL Kernel: $(uname -r)"
echo "Distro: $(lsb_release -ds 2>/dev/null || echo N/A)"
echo "SSH_AUTH_SOCK: ${SSH_AUTH_SOCK:-<unset>}"

echo
echo "== Check: npiperelay path from manifest =="
WINUSER="$(powershell.exe '$env:UserName' 2>/dev/null | tr -d '\r' || true)"
if [[ -z "$WINUSER" ]]; then
  echo "Could not determine Windows user" >&2; ok=0
fi
MANIFEST="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
  echo "Missing manifest at $MANIFEST — run install-win-ssh-agent.ps1" >&2; ok=0
else
  echo "Manifest OK: $MANIFEST"
fi

if command -v jq >/dev/null 2>&1; then
  NPIPERELAY="$(jq -r '.npiperelay_wsl' "$MANIFEST" 2>/dev/null || echo '')"
else
  NPIPERELAY="$(grep -oE '\"npiperelay_wsl\"\\s*:\\s*\"[^\"]+\"' "$MANIFEST" | sed -E 's/.*:\"([^\"]+)\"/\\1/')"
fi
if [[ -z "$NPIPERELAY" || ! -f "$NPIPERELAY" ]]; then
  echo "Invalid npiperelay path from manifest: '$NPIPERELAY'" >&2; ok=0
else
  echo "npiperelay: $NPIPERELAY"
fi

echo
echo "== Check: Agent keys visible in WSL =="
if ssh-add -l >/dev/null 2>&1; then
  ssh-add -l
else
  echo "ssh-add -l failed; the bridge may not be running." >&2; ok=0
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
if [[ $ok -eq 1 ]]; then
  echo "Preflight: OK"
  exit 0
else
  echo "Preflight: FAILED"
  exit 1
fi
