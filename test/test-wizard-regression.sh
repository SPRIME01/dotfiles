#!/usr/bin/env bash
# Regression tests for interactive-setup wizard (non-interactive simulation)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIZ=""
for cand in \
  "$ROOT/scripts/setup-wizard.sh" \
  "$ROOT/scripts/setup-wizard-improved.sh" \
  "$ROOT/install/interactive-setup.sh"
do
  if [[ -f "$cand" ]]; then WIZ="$cand"; break; fi
done
if [[ -z "$WIZ" ]]; then
  echo "SKIP: wizard script missing"; exit 0
fi

# Test selecting each profile via simulated input (1:minimal,2:developer,3:full)
for choice in 1 2 3; do
  if ! (printf '%s\nn\nn\n' "$choice" | DOTFILES_ROOT="$ROOT" bash "$WIZ" >/dev/null 2>&1); then
    echo "FAIL: wizard failed for selection $choice" >&2; exit 1
  fi
done

echo "PASS: wizard selections processed successfully"
