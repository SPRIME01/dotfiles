#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file (variant 2)..."

tmp_created=0
env_file="./.env"
cleanup() { [[ ${tmp_created:-0} -eq 1 ]] && [[ -n ${env_file:-} ]] && rm -f -- "$env_file"; }
trap cleanup EXIT

if [[ ! -f "$env_file" ]]; then
	env_file="$(mktemp)"
	cat >"$env_file" <<'EOF'
ALPHA=one
BETA=two three
EMPTY=
# comment
EOF
	tmp_created=1
fi

echo "Reading .env file directly with while loop (no IFS):"
line_num=0
while IFS= read -r line || [[ -n "$line" ]]; do
	line_num=$((line_num + 1))
	echo "Line $line_num: '$line'"
done <"$env_file"

[[ $tmp_created -eq 1 ]] && rm -f ./.env
echo "PASS: simple-read-test2"
