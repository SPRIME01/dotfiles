#!/bin/bash
load_env_file() {
    local env_file="$1"
    echo "Loading env file: $env_file"
    [[ -z "$env_file" || ! -f "$env_file" ]] && return 0

    while IFS='=' read -r key value || [ -n "$key" ]; do
        echo "Raw line - key: '$key', value: '$value'"

        # Skip blank lines and comments early
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace from key and value
        key="${key##*( )}"
        key="${key%%*( )}"
        value="${value##*( )}"
        value="${value%%*( )}"

        echo "After trim - key: '$key', value: '$value'"

        # Skip if key is empty after trimming
        [[ -z "$key" ]] && continue

        # Remove surrounding quotes if present
        if [[ "$value" =~ ^\"(.*)\"$ ]]; then
            value="${BASH_REMATCH[1]}"
            echo "Removed quotes - value: '$value'"
        elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi

        # Export the variable
        echo "Exporting: $key=$value"
        export "$key"="$value"
    done < "$env_file"
}

load_env_file ".env"
echo "Final GEMINI_API_KEY: '$GEMINI_API_KEY'"
