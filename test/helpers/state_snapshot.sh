#!/usr/bin/env bash
# Helper: Generate normalized state snapshot hash for idempotency tests.
# Usage: state_snapshot <root> [maxdepth]
set -euo pipefail
root="${1:-$HOME}"
maxdepth="${2:-4}"
# Exclude volatile files (logs, caches, font cache, history)
find "$root" -maxdepth "$maxdepth" \
  \( -name '*.log' -o -name '*.cache' -o -name 'history' -o -name '.zcompdump*' \) -prune -o \
  -type f -o -type l -o -type d | \
  sed "s#$root##" | LC_ALL=C sort | sha256sum | awk '{print $1}'
