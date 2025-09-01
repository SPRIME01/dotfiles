#!/usr/bin/env bash
# scripts/run-tests.sh - Run all tests using the unified test runner

set -euo pipefail

# Use the unified test runner
exec "$(dirname "${BASH_SOURCE[0]}")/../test/run-all-tests.sh"
