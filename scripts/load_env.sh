#!/usr/bin/env bash
# DEPRECATED: This file is deprecated and will be removed in a future version.
# Please use lib/env-loader.sh instead.
#
# This compatibility bridge provides backward compatibility while transitioning
# to the new modular environment loading system.

# Print deprecation warning
echo "Warning: scripts/load_env.sh is deprecated. Please use lib/env-loader.sh instead." >&2
echo "This compatibility bridge will be removed in a future version." >&2

# Determine the location of the new environment loader
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NEW_ENV_LOADER="$PROJECT_ROOT/lib/env-loader.sh"

# Check if the new loader exists and delegate to it
if [[ -f "$NEW_ENV_LOADER" ]]; then
	# Source the new loader
	source "$NEW_ENV_LOADER"

	# Provide backward compatibility for the old function name
	load_env_file() {
		echo "Warning: load_env_file() is deprecated. Use the new lib/env-loader.sh system." >&2
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
	# Fallback to original implementation if new system not available
	echo "Error: New environment loading system not found at $NEW_ENV_LOADER" >&2
	echo "Please ensure lib/env-loader.sh exists and is properly configured." >&2
	exit 1
fi
