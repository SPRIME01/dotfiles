#!/usr/bin/env bash
# Description: Run shell lint (shellcheck) and formatting check (shfmt) across repository.
# Category: quality
# Idempotent: yes
# Exit Codes: 0 success, >0 on any lint/format issue
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHFMT_BIN=${SHFMT_BIN:-shfmt}
SHELLCHECK_BIN=${SHELLCHECK_BIN:-shellcheck}

if ! command -v "$SHELLCHECK_BIN" >/dev/null 2>&1; then
  echo "⚠️ shellcheck not found. Install to enable linting (e.g., 'sudo apt install shellcheck')." >&2
  missing_sc=1
else
  missing_sc=0
fi

if ! command -v "$SHFMT_BIN" >/dev/null 2>&1; then
  echo "⚠️ shfmt not found. Install to enable format checks (e.g., 'go install mvdan.cc/sh/v3/cmd/shfmt@latest')." >&2
  missing_fmt=1
else
  missing_fmt=0
fi

if [[ $missing_sc -eq 1 && $missing_fmt -eq 1 ]]; then
  echo "No lint tools available; skipping (treating as success)."; exit 0
fi

# Gather shell scripts (exclude vendor/backups/.git)
mapfile -t FILES < <(git ls-files '*.sh' ':!:*/backups/*' 2>/dev/null || find "$ROOT_DIR" -type f -name '*.sh')

fail=0

# Guard: avoid calling shellcheck/shfmt with zero files (they can error on empty args)
if ((${#FILES[@]} == 0)); then
  echo "No shell files found; skipping."
  exit 0
fi

if [[ $missing_sc -eq 0 ]]; then
  echo "🔍 Running shellcheck..."
  "$SHELLCHECK_BIN" "${FILES[@]}" || fail=1
fi

if [[ $missing_fmt -eq 0 ]]; then
  echo "🔍 Checking formatting with shfmt..."
  # -d diff mode to detect changes needed
  if ! "$SHFMT_BIN" -d "${FILES[@]}"; then
    echo "❌ Formatting issues detected. Run: shfmt -w ${ROOT_DIR}"; fail=1
  fi
fi

if [[ $fail -eq 0 ]]; then
  echo "✅ Lint & format checks passed"
else
  echo "❌ Lint/format failures" >&2
fi
exit $fail
