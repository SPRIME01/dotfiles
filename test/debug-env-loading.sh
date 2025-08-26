#!/usr/bin/env bash
# Debug script for environment loading

set -euo pipefail

echo "Testing environment loading..."

# Source the environment loader
source ./lib/env-loader.sh

echo "Loading .env file..."
if [[ -f ./.env ]]; then
	echo "Testing simple read:"
	while read -r line; do
		echo "Line: $line"
	done <./.env
	echo "Now loading with load_env_file_secure:"
	load_env_file_secure "./.env" false
else
	echo "(no .env present, skipping)"
fi

echo "Done."
