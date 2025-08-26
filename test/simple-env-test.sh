#!/usr/bin/env bash
# Simple test for environment loading

set -euo pipefail

echo "Testing simple environment loading..."

# Simple test of reading .env file
echo "Reading .env file directly:"
if [[ -f ./.env ]]; then
	while IFS='=' read -r key value || [ -n "$key" ]; do
		echo "Key: '$key', Value: '$value'"
	done <./.env
else
	echo "(no .env present, skipping)"
fi

echo "Done."
