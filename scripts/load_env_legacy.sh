#!/bin/bash
# Legacy system compatibility bridge
# This file provides backward compatibility while transitioning to the new modular system

# Print deprecation warning
echo "Warning: scripts/load_env.sh is deprecated. Please use lib/env-loader.sh instead." >&2
echo "This compatibility bridge will be removed in a future version." >&2

# Determine the location of the new environment loader
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NEW_ENV_LOADER="$PROJECT_ROOT/lib/env-loader.sh"

# Check if the new loader exists
if [[ -f "$NEW_ENV_LOADER" ]]; then
	# Source the new loader
	source "$NEW_ENV_LOADER"

	# Provide backward compatibility for the old function name
	load_env_file() {
		echo "Warning: load_env_file() is deprecated. Use the new env-loader.sh system." >&2
		local env_file="$1"
		[[ -z "$env_file" || ! -f "$env_file" ]] && return 0

		# Use the new secure loading function
		load_env_file_secure "$env_file"
	}

	# If script is executed directly, use new system
	if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
		load_dotfiles_environment "$PROJECT_ROOT"
	fi
else
	# Fallback to old implementation if new system not available
	echo "Warning: New environment loading system not found, using legacy implementation." >&2

	# Original load_env_file function (kept for absolute backward compatibility)
	load_env_file() {
		local env_file="$1"
		[[ -z "$env_file" || ! -f "$env_file" ]] && return 0

		while IFS='=' read -r key value || [ -n "$key" ]; do
			[[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

			key="${key##*( )}"
			key="${key%%*( )}"
			value="${value##*( )}"
			value="${value%%*( )}"

			[[ -z "$key" ]] && continue

			if [[ "$value" =~ ^\"(.*)\"$ ]]; then
				value="${BASH_REMATCH[1]}"
			elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
				value="${BASH_REMATCH[1]}"
			fi

			export "$key"="$value"
		done <"$env_file"
	}

	# If script is executed directly, load .env from repository root
	if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
		env_file="$PROJECT_ROOT/.env"
		if [[ -f "$env_file" ]]; then
			load_env_file "$env_file"
		fi
	fi
fi
