#!/usr/bin/env bash
# list-hosts.sh — Preview expanded Host targets from ~/.ssh/config
set -euo pipefail
SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
if [[ ! -f "$SSH_CONFIG" ]]; then
  echo "No $SSH_CONFIG found." >&2; exit 1
fi
awk 'tolower($1)=="host"{for(i=2;i<=NF;i++) if($i!="*") print $i}' "$SSH_CONFIG" | tr -s ' ' '\n' | sort -u
