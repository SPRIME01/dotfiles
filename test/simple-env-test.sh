#!/usr/bin/env bash
# Simple test for environment loading

set -euo pipefail

echo "Testing simple environment loading..."

# Simple test of reading .env file
echo "Reading .env file directly:"
while IFS='=' read -r key value || [ -n "$key" ]; do
    echo "Key: '$key', Value: '$value'"
done < ./.env

echo "Done."
