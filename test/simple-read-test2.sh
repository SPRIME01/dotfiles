#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file..."

# Simple test of reading .env file
echo "Reading .env file directly with while loop (no IFS):"
line_num=0
while read -r line; do
	((line_num++))
	echo "Line $line_num: '$line'"
done <./.env

echo "Done."
