#!/usr/bin/env bash
# Load environment variables from a dotenv-style file.
#
# This script defines a function `load_env_file` that reads key=value pairs
# from a file and exports them into the current shell.  It supports simple
# unquoted values as well as values enclosed in single or double quotes.  It
# ignores empty lines and lines beginning with '#'.  Complex shell syntax
# (e.g. variable interpolation, command substitution) is not executed.

load_env_file() {
    local env_file="$1"
    # If no file is specified or file does not exist, return silently
    [[ -z "$env_file" || ! -f "$env_file" ]] && return 0

    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Trim whitespace from key and value
        key="${key%%*( )}"
        key="${key##*( )}"
        value="${value%%*( )}"
        value="${value##*( )}"

        # Skip blank lines and comments
        [[ -z "$key" ]] && continue
        [[ "$key" == \#* ]] && continue

        # Remove surrounding quotes if present
        if [[ "$value" =~ ^\"(.*)\"$ ]]; then
            value="${BASH_REMATCH[1]}"
        elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi

        # Export the variable
        export "$key"="$value"
    done < "$env_file"
}

# If this script is executed directly, load .env from repository root
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Derive project root relative to this script
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    project_root="$(cd "$script_dir/.." && pwd)"
    env_file="$project_root/.env"
    if [[ -f "$env_file" ]]; then
        load_env_file "$env_file"
    fi
fi