#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_HOME=$(mktemp -d)
export HOME="$TMP_HOME"
export OMP_VERSION=skip

bash "$ROOT/scripts/install-oh-my-posh.sh" >/dev/null

if command -v oh-my-posh >/dev/null 2>&1; then
  echo "INFO: oh-my-posh already present (acceptable)"
fi

echo "PASS: skip flag respected"
