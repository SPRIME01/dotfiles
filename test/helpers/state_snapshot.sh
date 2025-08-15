#!/usr/bin/env bash
# Helper: Generate normalized state snapshot hash for idempotency tests.
# Usage: state_snapshot <root> [maxdepth]
set -euo pipefail

# Validate and normalize root for deterministic snapshots
root="${1:-${HOME:-}}"
find "$root" -maxdepth "$maxdepth" \
  \( -name '*.log' -o -name '*.cache' -o -name 'history' -o -name '.zcompdump*' \) -prune -o \
  \( -type f -o -type l -o -type d \) -print | \
  sed -e "s#^$root/*##" | LC_ALL=C sort | { command -v sha256sum >/dev/null 2>&1 && sha256sum || shasum -a 256; } | awk '{print $1}'

# Resolve to absolute path when possible
if command -v realpath >/dev/null 2>&1; then
  root="$(realpath "$root")"
elif command -v readlink >/dev/null 2>&1; then
  root="$(readlink -f "$root" 2>/dev/null || echo "$root")"
fi

# Strip trailing slash for consistent sed replacements
root="${root%/}"

maxdepth="${2:-4}"
# Exclude volatile files (logs, caches, font cache, history)
find "$root" -maxdepth "$maxdepth" \
  \( -name '*.log' -o -name '*.cache' -o -name 'history' -o -name '.zcompdump*' \) -prune -o \
  -type f -o -type l -o -type d | \
  sed "s#$root##" | LC_ALL=C sort | sha256sum | awk '{print $1}'
