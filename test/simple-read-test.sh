#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file..."

tmp_created=0
if [[ ! -f ./.env ]]; then
    cat > ./.env <<EOF
FOO=bar
BAR=baz value
EMPTY=
# comment
EOF
    tmp_created=1
fi

echo "Reading .env file directly with while loop:"
line_num=0
while IFS='=' read -r key value; do
        ((line_num++))
        echo "Line $line_num: Key: '$key', Value: '$value'"
done < ./.env

[[ $tmp_created -eq 1 ]] && rm -f ./.env
echo "PASS: simple-read-test"
