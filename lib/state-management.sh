#!/usr/bin/env bash
# State management for dotfiles setup
# This script provides functions to track installation state and make setup idempotent

# State file location
DOTFILES_STATE_FILE="${DOTFILES_ROOT:-$HOME/dotfiles}/.dotfiles-state"

# Initialize state file if it doesn't exist
init_state_file() {
    if [[ ! -f "$DOTFILES_STATE_FILE" ]]; then
        cat > "$DOTFILES_STATE_FILE" <<EOF
# Dotfiles installation state
# Format: COMPONENT=STATUS (installed|skipped|failed)
# Generated: $(date -Iseconds)
EOF
        echo "✅ Initialized state file: $DOTFILES_STATE_FILE"
    fi
}

# Check if a component is already installed
is_component_installed() {
    local component="$1"
    init_state_file

    if grep -q "^${component}=installed$" "$DOTFILES_STATE_FILE" 2>/dev/null; then
        return 0  # Component is installed
    else
        return 1  # Component is not installed
    fi
}

# Mark a component as installed
mark_component_installed() {
    local component="$1"
    init_state_file

    # Remove any existing entry for this component
    sed -i "/^${component}=/d" "$DOTFILES_STATE_FILE" 2>/dev/null || true

    # Add new entry
    echo "${component}=installed" >> "$DOTFILES_STATE_FILE"
    echo "✅ Marked $component as installed"
}

# Mark a component as skipped
mark_component_skipped() {
    local component="$1"
    local reason="${2:-user choice}"
    init_state_file

    # Remove any existing entry for this component
    sed -i "/^${component}=/d" "$DOTFILES_STATE_FILE" 2>/dev/null || true

    # Add new entry
    echo "${component}=skipped # $reason" >> "$DOTFILES_STATE_FILE"
    echo "ℹ️  Marked $component as skipped ($reason)"
}

# Mark a component as failed
mark_component_failed() {
    local component="$1"
    local error="${2:-unknown error}"
    init_state_file

    # Remove any existing entry for this component
    sed -i "/^${component}=/d" "$DOTFILES_STATE_FILE" 2>/dev/null || true

    # Add new entry
    echo "${component}=failed # $error" >> "$DOTFILES_STATE_FILE"
    echo "❌ Marked $component as failed ($error)"
}

# Reset a component's state (for re-installation)
reset_component_state() {
    local component="$1"
    init_state_file

    sed -i "/^${component}=/d" "$DOTFILES_STATE_FILE" 2>/dev/null || true
    echo "🔄 Reset state for $component"
}

# Show installation status
show_installation_status() {
    init_state_file

    echo "📋 Current installation status:"
    echo "================================"

    if [[ -s "$DOTFILES_STATE_FILE" ]]; then
        # Parse and display status with colors
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^#.*$ ]] || [[ -z "$line" ]]; then
                continue
            fi

            if [[ "$line" =~ ^([^=]+)=installed.*$ ]]; then
                echo "✅ ${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^([^=]+)=skipped.*$ ]]; then
                echo "⏭️  ${BASH_REMATCH[1]} (skipped)"
            elif [[ "$line" =~ ^([^=]+)=failed.*$ ]]; then
                echo "❌ ${BASH_REMATCH[1]} (failed)"
            fi
        done < "$DOTFILES_STATE_FILE"
    else
        echo "No components installed yet"
    fi
    echo "================================"
}

# Get list of installed components
get_installed_components() {
    init_state_file
    grep "=installed$" "$DOTFILES_STATE_FILE" 2>/dev/null | cut -d'=' -f1 || true
}

# Get list of failed components
get_failed_components() {
    init_state_file
    grep "=failed" "$DOTFILES_STATE_FILE" 2>/dev/null | cut -d'=' -f1 || true
}

# Check if any setup has been done
has_any_setup_been_done() {
    init_state_file
    [[ -s "$DOTFILES_STATE_FILE" ]] && grep -q "=" "$DOTFILES_STATE_FILE" 2>/dev/null
}

# Smart prompt - only ask if component is not already installed
smart_prompt_yes_no() {
    local component="$1"
    local prompt="$2"
    local default="$3"
    local force="${4:-false}"

    # Check if already installed and not forcing
    if [[ "$force" != "true" ]] && is_component_installed "$component"; then
        echo "✅ $component already installed (skipping prompt)"
        return 0  # Already installed, return success
    fi

    # If already failed, ask if they want to retry
    if grep -q "^${component}=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
        echo "⚠️  $component previously failed. Would you like to retry?"
        local retry_prompt="Retry $component?"
        local reply
        if [ "$default" = "y" ]; then
            retry_prompt="$retry_prompt [Y/n] "
        else
            retry_prompt="$retry_prompt [y/N] "
        fi
        read -r -p "$retry_prompt" reply
        reply="${reply:-$default}"
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            reset_component_state "$component"
            return 0
        else
            return 1
        fi
    fi

    # Standard prompt for new components
    local reply
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    read -r -p "$prompt" reply
    reply="${reply:-$default}"
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        return 0
    else
        mark_component_skipped "$component"
        return 1
    fi
}
