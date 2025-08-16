#!/usr/bin/env bash
# setup-wsl2-remote-access.sh
# Placeholder script for WSL2 remote access setup. Previously empty; add safe header.
set -euo pipefail

echo "TODO: WSL2 remote access setup not implemented yet." >&2
# Opt-in to stricter behavior in CI: set FAIL_ON_NOOP=1 to make this script return non-zero.
if [[ "${FAIL_ON_NOOP:-}" == "1" ]]; then
  exit 2
else
  exit 0
fi
