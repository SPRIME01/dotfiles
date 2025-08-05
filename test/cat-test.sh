#!/usr/bin/env bash
# Test using cat to read .env file

set -euo pipefail

echo "Testing cat read of .env file..."

# Test using cat
echo "Using cat to read .env file:"
cat ./.env

echo "Done."
