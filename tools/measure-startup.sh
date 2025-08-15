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

# Portable millisecond timestamp helper:
now_ms() {
  # Prefer GNU date if available (supports +%s%3N)
  if date +%s%3N >/dev/null 2>&1; then
    date +%s%3N
    return
  fi
measure_shell() {
  local sh=$1
  local iters=$2
  local tmpfile
  tmpfile=$(mktemp)
  # Ensure cleanup even on early exit
  trap 'rm -f "$tmpfile"' RETURN
  for i in $(seq 1 "$iters"); do
    # Use POSIX time -p for portability across GNU/BSD
    # Measure login + interactive shell that immediately exits
    local secs ms
    secs=$({ command time -p "$sh" -lic 'exit'; } 2>&1 >/dev/null | awk '/^real /{print $2}')
    # Convert seconds (possibly fractional) to milliseconds
    ms=$(awk -v s="$secs" 'BEGIN{printf "%.0f", s*1000}')
    echo "$ms" >> "$tmpfile"
  done
  local avg max min
  avg=$(awk '{s+=$1} END {if(NR>0) printf("%.2f", s/NR);}' "$tmpfile")
  max=$(awk 'BEGIN{m=0} {if($1>m)m=$1} END{print m}' "$tmpfile")
  min=$(awk 'BEGIN{m=1e12} {if($1<m)m=$1} END{print m}' "$tmpfile")
  echo "Shell: $sh  Iterations: $iters  Avg(ms): $avg  Min(ms): $min  Max(ms): $max"
}
  local tmpfile
  tmpfile=$(mktemp)
  for ((i=1; i<=iters; i++)); do
    # Use time builtin via /usr/bin/time for consistent formatting
    local start end dur
    start="$(now_ms)"
    # Use -lic to simulate login + interactive for the given shell
    "$sh" -lic 'true' >/dev/null 2>&1 || true
    end="$(now_ms)"
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
  measure_shell "$s" "$ITERATIONS"
done

echo "Done."
