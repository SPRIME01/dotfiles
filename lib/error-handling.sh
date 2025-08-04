#!/usr/bin/env bash
# lib/error-handling.sh - Comprehensive error handling for dotfiles

# Global error handling setup
set -euo pipefail

# Error trap function
error_trap() {
    local exit_code=$?
    local line_number=$1
    local bash_lineno=$2
    local last_command=$3
    local funcname=("${4:-}")

    echo "Error: Command '$last_command' failed with exit code $exit_code on line $line_number" >&2

    # Log to file if available
    if [[ -n "${DOTFILES_LOG_FILE:-}" ]]; then
        echo "$(date): Error in ${BASH_SOURCE[1]:-unknown}:$line_number - $last_command" >> "$DOTFILES_LOG_FILE"
    fi

    # Don't exit if we're in a subshell or being sourced
    if [[ $BASH_SUBSHELL -eq 0 && "${BASH_SOURCE[0]}" == "${0}" ]]; then
        exit $exit_code
    fi

    return $exit_code
}

# Set up error trapping
setup_error_handling() {
    trap 'error_trap $LINENO $BASH_LINENO "$BASH_COMMAND" "${FUNCNAME[@]}"' ERR
}

# Safe source function with error handling
safe_source() {
    local file="$1"
    local required="${2:-false}"
    local description="${3:-$file}"

    if [[ -f "$file" ]]; then
        if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
            echo "Sourcing: $description" >&2
        fi

        # Source in a subshell first to check for syntax errors
        if ! (source "$file") >/dev/null 2>&1; then
            echo "Error: Syntax error in $description" >&2
            if [[ "$required" == "true" ]]; then
                return 1
            else
                echo "Warning: Skipping $description due to errors" >&2
                return 0
            fi
        fi

        # Actually source the file
        if ! source "$file"; then
            echo "Error: Failed to source $description" >&2
            if [[ "$required" == "true" ]]; then
                return 1
            fi
        fi
    elif [[ "$required" == "true" ]]; then
        echo "Error: Required file not found: $description" >&2
        return 1
    elif [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
        echo "Optional file not found: $description" >&2
    fi

    return 0
}

# Wrapper for commands that might fail
safe_command() {
    local description="$1"
    shift

    if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
        echo "Running: $description" >&2
    fi

    if ! "$@"; then
        echo "Warning: Failed to execute: $description" >&2
        return 1
    fi

    return 0
}
