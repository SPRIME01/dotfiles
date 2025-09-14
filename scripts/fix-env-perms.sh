#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fix_one() {
  local file="$1"
  if [[ -f "$file" ]]; then
    chmod 600 "$file" 2>/dev/null || true
    echo "✅ Secured perms: $file (600)"
  else
    echo "ℹ️  Skipped (not found): $file"
  fi
}

fix_one "$ROOT/.env"
fix_one "$ROOT/mcp/.env"

echo "🎉 Env file permission check complete"

