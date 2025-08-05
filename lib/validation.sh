#!/usr/bin/env bash
# lib/validation.sh - Input validation utilities for dotfiles

# Validate environment file exists and has secure permissions
validate_env_file() {
    local env_file="$1"
    local required="${2:-false}"

    if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
        echo "Starting validate_env_file with env_file='$env_file', required='$required'" >&2
    fi

    # Check if file exists
    if [[ ! -f "$env_file" ]]; then
        if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
            echo "File does not exist: $env_file" >&2
        fi
        if [[ "$required" == "true" ]]; then
            echo "Error: Required environment file not found: $env_file" >&2
            return 1
        else
            if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
                echo "Optional file, skipping validation" >&2
            fi
            return 0  # Optional file, skip validation
        fi
    fi

    if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
        echo "File exists: $env_file" >&2
    fi

    # Check file permissions (should not be world-readable for security)
    local perms
    if command -v stat >/dev/null 2>&1; then
        # Linux/GNU stat
        perms=$(stat -c %a "$env_file" 2>/dev/null)
        if [[ -z "$perms" ]]; then
            # macOS/BSD stat
            perms=$(stat -f %A "$env_file" 2>/dev/null)
        fi

        if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
            echo "File permissions: $perms" >&2
        fi

        if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
            echo "Warning: $env_file has potentially insecure permissions: $perms" >&2
            echo "Recommended: chmod 600 $env_file" >&2
        fi
    fi

    return 0
}

# Validate required environment variables are set
validate_required_environment() {
    local missing_vars=()

    # Check for critical environment variables
    [[ -z "${DOTFILES_ROOT:-}" ]] && missing_vars+=("DOTFILES_ROOT")

    # Check for API keys if they should be present
    if [[ -f "${DOTFILES_ROOT:-}/.env" ]] && grep -q "GEMINI_API_KEY" "${DOTFILES_ROOT:-}/.env" 2>/dev/null; then
        [[ -z "${GEMINI_API_KEY:-}" ]] && missing_vars+=("GEMINI_API_KEY")
    fi

    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "Error: Missing required environment variables: ${missing_vars[*]}" >&2
        echo "Please check your .env configuration" >&2
        return 1
    fi

    return 0
}

# Validate a key=value pair from environment file
validate_env_pair() {
    local key="$1"
    local value="$2"

    # Key validation
    if [[ -z "$key" ]]; then
        return 1  # Empty key
    fi

    if [[ "$key" =~ [^A-Za-z0-9_] ]]; then
        echo "Warning: Environment variable key contains invalid characters: $key" >&2
    fi

    # Value validation (basic safety checks)
    if [[ "$value" =~ [\$\`] ]]; then
        echo "Warning: Environment variable value contains potentially dangerous characters: $key" >&2
    fi

    return 0
}
