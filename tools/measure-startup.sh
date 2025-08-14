#!/usr/bin/env bash
# Description: Measure shell startup time for bash and zsh (login + interactive) to establish a baseline.
# Category: diagnostic
# Dependencies: bash, zsh, date, awk
# Idempotent: yes (read-only)
# Inputs: ITERATIONS (default 5)
# Outputs: Timing summary to stdout
# Exit Codes: 0 success, >0 failure
set -euo pipefail

ITERATIONS=${ITERATIONS:-5}
SHELLS=()
command -v bash >/dev/null 2>&1 && SHELLS+=(bash)
command -v zsh >/dev/null 2>&1 && SHELLS+=(zsh)

if [[ ${#SHELLS[@]} -eq 0 ]]; then
  echo "No supported shells found" >&2
  exit 1
fi

measure_shell() {
  local sh=$1
  local iters=$2
  local total=0
  local tmpfile
  tmpfile=$(mktemp)
  for i in $(seq 1 "$iters"); do
    # Use time builtin via /usr/bin/time for consistent formatting
    local start end dur
    start=$(date +%s%3N)
    # Use -lic to simulate login + interactive (bash) / zsh -lic
    if [[ $sh == bash ]]; then
      $sh -lic 'true' >/dev/null 2>&1 || true
    else
      $sh -lic 'true' >/dev/null 2>&1 || true
    fi
    end=$(date +%s%3N)
    dur=$((end-start))
    echo "$dur" >> "$tmpfile"
  done
  local avg max min
  avg=$(awk '{s+=$1} END {if(NR>0) printf("%.2f", s/NR);}' "$tmpfile")
  max=$(awk 'BEGIN{m=0} {if($1>m)m=$1} END{print m}' "$tmpfile")
  min=$(awk 'BEGIN{m=1e12} {if($1<m)m=$1} END{print m}' "$tmpfile")
  echo "Shell: $sh  Iterations: $iters  Avg(ms): $avg  Min(ms): $min  Max(ms): $max"
  rm -f "$tmpfile"
}

echo "⏱️  Measuring shell startup times (ITERATIONS=$ITERATIONS)"
for s in "${SHELLS[@]}"; do
  measure_shell "$s" "$ITERATIONS"
done

echo "Done."
