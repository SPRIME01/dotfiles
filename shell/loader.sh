#!/bin/bash
# Modular shell configuration loader
# Part of the modular dotfiles configuration system
#
# This script loads shell configuration in a modular way:
# 1. Common configuration (all shells, all platforms)
# 2. Platform-specific configuration (Linux/macOS/Windows)
# 3. Shell-specific configuration (bash/zsh)

# Determine the directory where this script is located
if [[ -n "$BASH_VERSION" ]]; then
    SHELL_CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "$ZSH_VERSION" ]]; then
    SHELL_CONFIG_ROOT="$(cd "$(dirname "${(%):-%N}")" && pwd)"
else
    # Fallback for other shells
    SHELL_CONFIG_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

# Determine current shell
if [[ -n "$BASH_VERSION" ]]; then
    CURRENT_SHELL="bash"
elif [[ -n "$ZSH_VERSION" ]]; then
    CURRENT_SHELL="zsh"
else
    CURRENT_SHELL="unknown"
fi

# Determine platform
case "$OSTYPE" in
    linux*)
        CURRENT_PLATFORM="linux"
        ;;
    darwin*)
        CURRENT_PLATFORM="macos"
        ;;
    msys*|cygwin*|mingw*)
        CURRENT_PLATFORM="windows"
        ;;
    *)
        CURRENT_PLATFORM="unknown"
        ;;
esac

# Function to safely source a file
safe_source() {
    local file="$1"
    if [[ -f "$file" && -r "$file" ]]; then
        source "$file"
        return 0
    else
        echo "Warning: Could not load $file" >&2
        return 1
    fi
}

# Load common configuration (all shells, all platforms)
echo "Loading modular shell configuration..."

# 1. Load common environment variables
safe_source "$SHELL_CONFIG_ROOT/common/environment.sh"

# 2. Load common aliases
safe_source "$SHELL_CONFIG_ROOT/common/aliases.sh"

# 3. Load common functions
safe_source "$SHELL_CONFIG_ROOT/common/functions.sh"

# 4. Load platform-specific configuration
if [[ "$CURRENT_PLATFORM" != "unknown" ]]; then
    safe_source "$SHELL_CONFIG_ROOT/platform-specific/$CURRENT_PLATFORM.sh"
else
    echo "Warning: Unknown platform '$OSTYPE', skipping platform-specific configuration" >&2
fi

# 5. Load shell-specific configuration
if [[ "$CURRENT_SHELL" != "unknown" ]]; then
    safe_source "$SHELL_CONFIG_ROOT/$CURRENT_SHELL/config.sh"
else
    echo "Warning: Unknown shell, skipping shell-specific configuration" >&2
fi

# Export variables for use by other scripts
export SHELL_CONFIG_ROOT
export CURRENT_SHELL
export CURRENT_PLATFORM

echo "Modular shell configuration loaded (shell: $CURRENT_SHELL, platform: $CURRENT_PLATFORM)"
