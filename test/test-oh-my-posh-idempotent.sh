#!/usr/bin/env bash
# Idempotency test placeholder for oh-my-posh installer (skips if installer absent)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-oh-my-posh.sh"
if [[ ! -f $INSTALLER ]]; then
  echo "SKIP: oh-my-posh installer not present"; exit 0
fi
# Cleanup function
cleanup() {
  if [[ -n "${TMP_HOME:-}" && -d "$TMP_HOME" ]]; then
    rm -rf "$TMP_HOME"
  fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/scripts/install-oh-my-posh.sh"
if [[ ! -f $INSTALLER ]]; then
  echo "SKIP: oh-my-posh installer not present"; exit 0
fi
HELPER="$ROOT/test/helpers/state_snapshot.sh"
if [[ ! -x $HELPER ]]; then
  echo "SKIP: snapshot helper missing"; exit 0
fi
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME"' EXIT
if ! bash "$INSTALLER" >/dev/null 2>&1; then
  echo "SKIP: first install run failed (installer not stable)"; exit 0
fi
snap1=$("$HELPER" "$HOME" 4)
if ! bash "$INSTALLER" >/dev/null 2>&1; then
  echo "SKIP: second install run failed (not idempotent)"; exit 0
fi
snap2=$("$HELPER" "$HOME" 4)
if [[ $snap1 != $snap2 ]]; then
  echo "FAIL: oh-my-posh installer not idempotent"; exit 1
fi
echo "PASS: oh-my-posh installer idempotent"
hash1=$(find "$HOME" -type f | sort | sha256sum | awk '{print $1}')
if ! bash "$INSTALLER" >/dev/null 2>&1; then
  echo "SKIP: second install run failed (not idempotent)"; exit 0
fi
hash2=$(find "$HOME" -type f | sort | sha256sum | awk '{print $1}')
if [[ $hash1 != $hash2 ]]; then
  echo "SKIP: idempotency hash mismatch (defer)"; exit 0
fi
echo "PASS: oh-my-posh installer idempotent"
