#!/usr/bin/env bash
# lib/platform-detection.sh - OS and shell detection utilities

detect_platform() {
    local platform=""
    local shell_name=""

    # Detect OS
    case "$(uname -s)" in
        Linux*)   platform="linux" ;;
        Darwin*)  platform="macos" ;;
        CYGWIN*)  platform="windows" ;;
        MINGW*)   platform="windows" ;;
        *)        platform="unknown" ;;
    esac

    # Detect WSL
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        platform="wsl"
    fi

    # Detect shell
    shell_name="$(basename "${SHELL:-bash}")"

    export DOTFILES_PLATFORM="$platform"
    export DOTFILES_SHELL="$shell_name"

    # Debug output if requested
    if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
        echo "Platform detected: $platform, Shell: $shell_name" >&2
    fi
}

# Get the absolute path to dotfiles root
get_dotfiles_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$(cd "$script_dir/.." && pwd)"
}

# Validate that dotfiles root is properly set
validate_dotfiles_root() {
    local dotfiles_root="$1"

    if [[ -z "$dotfiles_root" ]]; then
        echo "Error: DOTFILES_ROOT not provided" >&2
        return 1
    fi

    if [[ ! -d "$dotfiles_root" ]]; then
        echo "Error: DOTFILES_ROOT directory does not exist: $dotfiles_root" >&2
        return 1
    fi

    if [[ ! -f "$dotfiles_root/.shell_common.sh" ]]; then
        echo "Error: Invalid DOTFILES_ROOT - missing .shell_common.sh: $dotfiles_root" >&2
        return 1
    fi

    return 0
}
