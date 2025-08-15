#!/usr/bin/env bash

# Shell startup time profiler
profile_shell_startup() {
	local shell_name="$1"
	local iterations="${2:-5}"

	echo "Profiling $shell_name startup time ($iterations iterations)..."

	for ((i = 1; i <= iterations; i++)); do
		/usr/bin/time -f "%e" "$shell_name" -i -c exit 2>&1
	done | awk '{sum+=$1} END {print "Average:", sum/NR, "seconds"}'
}

# Main execution
if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <shell_name> [iterations]"
	echo "Example: $0 zsh 10"
	exit 1
fi

profile_shell_startup "$1" "$2"
