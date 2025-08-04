#!/usr/bin/env bash
# Debug script for environment loading

set -euo pipefail

echo "Testing environment loading..."

# Source the environment loader
source ./lib/env-loader.sh

echo "Loading .env file..."
load_env_file_secure "./.env" false

echo "Done."
