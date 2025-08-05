#!/usr/bin/env bash
# Simple test for reading .env file

set -euo pipefail

echo "Testing simple read of .env file..."

# Simple test of reading .env file
echo "Reading .env file directly with while loop:"
line_num=0
while IFS='=' read -r key value; do
    ((line_num++))
    echo "Line $line_num: Key: '$key', Value: '$value'"
done < ./.env

echo "Done."
