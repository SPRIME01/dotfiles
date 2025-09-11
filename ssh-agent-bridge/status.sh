#!/usr/bin/env bash
# status.sh — Summarize SSH agent bridge health & recent deploy state
set -euo pipefail

LOGDIR="$HOME/.ssh/logs"
MANIFEST_WIN=""
WINUSER=""
if command -v powershell.exe >/dev/null 2>&1; then
  WINUSER=$(powershell.exe -NoProfile -NonInteractive -Command '$env:UserName' 2>/dev/null | tr -d '\r' | tail -n1 || true)
fi
if [[ -z "$WINUSER" && -d /mnt/c/Users ]]; then
  if [[ -d "/mnt/c/Users/$USER" ]]; then WINUSER="$USER"; else WINUSER=$(ls -1 /mnt/c/Users 2>/dev/null | head -n1 || true); fi
fi
[[ -n "$WINUSER" ]] && MANIFEST_WIN="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"

echo "== SSH Bridge Status =="
echo "WSL:        ${WSL_DISTRO_NAME:-no}" 
echo "WindowsUser: ${WINUSER:-unknown}" 
echo "Manifest:   ${MANIFEST_WIN:-<unknown>}"
if [[ -f "$MANIFEST_WIN" ]]; then
  if command -v jq >/dev/null 2>&1; then
    jq '. | {npiperelay_wsl, ssh_key_path}' "$MANIFEST_WIN" 2>/dev/null || true
  else
    grep -E 'npiperelay_wsl|ssh_key_path' "$MANIFEST_WIN" || true
  fi
else
  echo "(missing manifest)"
fi

echo
echo "== Agent Keys =="
if ssh-add -l >/dev/null 2>&1; then
  ssh-add -l || true
else
  echo "ssh-add -l failed (bridge down?)"
fi

echo
echo "== Recent Deploy State =="
STATE_FILE=$(ls -1t "$LOGDIR"/deploy-ssh-key_state.tsv 2>/dev/null | head -n1 || true)
if [[ -n "$STATE_FILE" && -f "$STATE_FILE" ]]; then
  echo "State file: $STATE_FILE"
  total=$(awk 'NF>0{c++} END{print c+0}' "$STATE_FILE")
  done=$(awk '$2=="complete"{c++} END{print c+0}' "$STATE_FILE")
  failed=$(awk '$2 ~ /^failed_/{c++} END{print c+0}' "$STATE_FILE")
  echo "Total:   $total"
  echo "Done:    $done"
  echo "Failed:  $failed"
  if [[ $failed -gt 0 ]]; then
    echo "Failed hosts:"; awk -F'\t' '$2 ~ /^failed_/{print " - "$1" ("$2")"}' "$STATE_FILE" | sort -u
  fi
else
  echo "No deploy state file found."
fi

echo
echo "== Recent Bridge Logs =="
ls -1t "$LOGDIR"/wsl-agent-bridge_*.log 2>/dev/null | head -n3 || echo "No bridge logs."

echo
echo "Done."