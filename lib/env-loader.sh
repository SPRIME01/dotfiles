#!/usr/bin/env bash
# lib/env-loader.sh - Consolidated environment loader with security
#
# Environment Variables:
#   DOTFILES_DEBUG=true - Enable verbose debug output to stderr

# Source dependencies with safe error handling
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/error-handling.sh" ]]; then
    # Fallback: assume we're in dotfiles/lib/
    SCRIPT_DIR="$DOTFILES_ROOT/lib"
fi

# Source dependencies safely
. "$SCRIPT_DIR/error-handling.sh" 2>/dev/null || true
. "$SCRIPT_DIR/platform-detection.sh" 2>/dev/null || true
. "$SCRIPT_DIR/validation.sh" 2>/dev/null || true

# Secure environment file loader
load_env_file_secure() {
    local env_file="$1"
    local required="${2:-false}"

    # Validate file existence and permissions
    if ! validate_env_file "$env_file" "$required"; then
        return 1
    fi

    # Skip if file doesn't exist and it's optional
    [[ -z "$env_file" || ! -f "$env_file" ]] && return 0

    # Read and process the file safely
    while IFS= read -r line; do
        # Skip blank lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Split line into key and value
        IFS='=' read -r key value <<< "$line"

        # Skip invalid lines
        [[ -z "$key" ]] && continue

        # Trim whitespace
        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"

        # Validate the key=value pair
        if ! validate_env_pair "$key" "$value"; then
            echo "Warning: Invalid environment pair: $key=$value" >&2
            continue
        fi

        # Remove surrounding quotes if present
        if [[ "$value" =~ ^\".*\"$ || "$value" =~ ^\'.*\'$ ]]; then
            value="${value:1:-1}"
        fi

        # Export the variable
        export "$key"="$value"
    done < <(grep -v '^[[:space:]]*#' "$env_file" | grep -v '^$')

    return 0
}

# Export computed variables based on environment
export_computed_variables() {
    local dotfiles_root="$1"

    # Set default PROJECTS_ROOT if not already set
    if [[ -z "${PROJECTS_ROOT:-}" ]]; then
        export PROJECTS_ROOT="$HOME/projects"
    fi

    # Set WSL-specific variables if needed
    if [[ "$DOTFILES_PLATFORM" == "wsl" ]]; then
        if [[ -z "$WSL_USER" ]]; then
            export WSL_USER="$USER"
        fi

        if [[ -z "$WSL_PROJECTS_PATH" ]]; then
            export WSL_PROJECTS_PATH="$HOME/projects"
        fi
    fi

    # Set Volta path if directory exists
    if [[ -d "$HOME/.volta" ]]; then
        export VOLTA_HOME="$HOME/.volta"
    fi
}

# Main environment loading function
load_dotfiles_environment() {
    local dotfiles_root="${1:-}"

    # Set up error handling
    setup_error_handling

    # Detect platform first
    detect_platform

    # Validate inputs
    if ! validate_dotfiles_root "$dotfiles_root"; then
        return 1
    fi

    # Ensure DOTFILES_ROOT is set and exported
    export DOTFILES_ROOT="$dotfiles_root"

    # Load environment files in order of precedence
    load_env_file_secure "$dotfiles_root/.env.defaults" false
    load_env_file_secure "$dotfiles_root/.env" false
    load_env_file_secure "$dotfiles_root/mcp/.env" false

    # Export computed variables
    export_computed_variables "$dotfiles_root"

    # Final validation
    if ! validate_required_environment; then
        echo "Warning: Environment validation failed" >&2
        return 1
    fi

    return 0
}
