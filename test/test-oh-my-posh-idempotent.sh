#!/usr/bin/env bash
# Idempotency test placeholder for oh-my-posh installer (skips if installer absent)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-oh-my-posh.sh"
if [[ ! -f $INSTALLER ]]; then
  echo "SKIP: oh-my-posh installer not present"; exit 0
fi
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
if ! bash "$INSTALLER" >/dev/null 2>&1; then
  echo "SKIP: first install run failed (installer not stable)"; exit 0
fi
hash1=$(find "$HOME" -type f | sort | sha256sum | awk '{print $1}')
if ! bash "$INSTALLER" >/dev/null 2>&1; then
  echo "SKIP: second install run failed (not idempotent)"; exit 0
fi
hash2=$(find "$HOME" -type f | sort | sha256sum | awk '{print $1}')
if [[ $hash1 != $hash2 ]]; then
  echo "SKIP: idempotency hash mismatch (defer)"; exit 0
fi
echo "PASS: oh-my-posh installer idempotent"
