#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file (variant 2)..."

tmp_created=0
if [[ ! -f ./.env ]]; then
    cat > ./.env <<EOF
ALPHA=one
BETA=two three
EMPTY=
# comment
EOF
    tmp_created=1
fi

echo "Reading .env file directly with while loop (no IFS):"
line_num=0
while read -r line; do
        ((line_num++))
        echo "Line $line_num: '$line'"
done < ./.env

[[ $tmp_created -eq 1 ]] && rm -f ./.env
echo "PASS: simple-read-test2"
