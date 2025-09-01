#!/usr/bin/env bash
# Full test for environment loading

set -euo pipefail

echo "Testing full environment loading..."

# Source the environment loader
source ./lib/env-loader.sh

echo "Loading .env file with load_env_file_secure:"
load_env_file_secure "./.env" false

echo "GEMINI_API_KEY is now set to: '${GEMINI_API_KEY:-NOT SET}'"

echo "Done."
