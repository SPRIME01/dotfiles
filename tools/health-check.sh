#!/usr/bin/env bash

# Dotfiles Health Check Script
# Performs essential environment and dependency checks

# Initialize exit code (0 = success)
exit_code=0

echo "=== Dotfiles Health Check ==="

# 1. Check DOTFILES_ROOT environment variable
if [ -z "$DOTFILES_ROOT" ]; then
	echo "❌ Error: DOTFILES_ROOT environment variable is not set"
	exit_code=1
else
	echo "✅ DOTFILES_ROOT is set to: $DOTFILES_ROOT"
fi

# 2. Check .env file permissions
env_file="$DOTFILES_ROOT/.env"
if [ -f "$env_file" ]; then
	permissions=$(stat -c "%a" "$env_file")
	if [ "$permissions" != "600" ]; then
		echo "❌ Error: .env file has incorrect permissions ($permissions). Should be 600"
		exit_code=1
	else
		echo "✅ .env file has correct permissions (600)"
	fi
else
	echo "⚠️ Warning: .env file not found at $env_file"
fi

# 3. Check dependencies
dependencies=("git" "curl" "wget")
for dep in "${dependencies[@]}"; do
	if ! command -v "$dep" &>/dev/null; then
		echo "❌ Error: $dep is not installed"
		exit_code=1
	else
		echo "✅ $dep is installed"
	fi
done

# Final status
if [ $exit_code -eq 0 ]; then
	echo "✅ All health checks passed"
else
	echo "❌ Some health checks failed"
fi

exit $exit_code
