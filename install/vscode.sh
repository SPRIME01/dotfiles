#!/bin/bash

# VS Code Settings Installation Script
# Part of dotfiles project - cross-platform VS Code configuration

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect the current platform context
detect_context() {
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        echo "wsl"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "darwin"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Check if jq is available for JSON merging
check_jq() {
    if ! command -v jq &> /dev/null; then
        log_warning "jq not found. Installing jq for JSON merging..."

        case "$(detect_context)" in
            "wsl"|"linux")
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S --noconfirm jq
                else
                    log_error "Could not install jq automatically. Please install jq manually."
                    return 1
                fi
                ;;
            "darwin")
                if command -v brew &> /dev/null; then
                    brew install jq
                else
                    log_error "Homebrew not found. Please install jq manually: brew install jq"
                    return 1
                fi
                ;;
            *)
                log_error "Cannot install jq automatically on this platform. Please install jq manually."
                return 1
                ;;
        esac
    fi
}

# Setup VS Code configuration for a specific context
setup_vscode() {
    local context="$1"

    log_info "Setting up VS Code configuration for context: $context"

    # Define VS Code settings directories for each platform
    case "$context" in
        "wsl")
            # WSL2 - Setup both WSL and Windows VS Code settings
            WSL_VSCODE_DIR="$HOME/.vscode-server/data/Machine"
            WINDOWS_VSCODE_DIR="/mnt/c/Users/$(powershell.exe -Command "Write-Host \$env:USERNAME" 2>/dev/null | tr -d '\r' || echo "$(whoami)")/AppData/Roaming/Code/User"

            # Create directories if they don't exist
            mkdir -p "$WSL_VSCODE_DIR" 2>/dev/null || true
            mkdir -p "$WINDOWS_VSCODE_DIR" 2>/dev/null || true

            # Setup WSL VS Code Server settings
            if [[ -d "$WSL_VSCODE_DIR" ]]; then
                setup_settings_file "$WSL_VSCODE_DIR/settings.json" "wsl"
                log_success "Linked VS Code Server settings (WSL2)"
            else
                log_warning "VS Code Server directory not found: $WSL_VSCODE_DIR"
            fi

            # Setup Windows VS Code settings (for Remote-WSL usage)
            if [[ -d "$WINDOWS_VSCODE_DIR" ]]; then
                setup_settings_file "$WINDOWS_VSCODE_DIR/settings.json" "windows"
                log_success "Linked Windows VS Code settings (Remote-WSL)"
            else
                log_warning "Windows VS Code directory not found: $WINDOWS_VSCODE_DIR"
            fi
            ;;
        "linux")
            VSCODE_CONFIG_DIR="$HOME/.config/Code/User"
            mkdir -p "$VSCODE_CONFIG_DIR"
            setup_settings_file "$VSCODE_CONFIG_DIR/settings.json" "linux"
            log_success "Linked Linux VS Code settings"
            ;;
        "darwin")
            VSCODE_CONFIG_DIR="$HOME/Library/Application Support/Code/User"
            mkdir -p "$VSCODE_CONFIG_DIR"
            setup_settings_file "$VSCODE_CONFIG_DIR/settings.json" "darwin"
            log_success "Linked macOS VS Code settings"
            ;;
        "windows")
            VSCODE_CONFIG_DIR="$APPDATA/Code/User"
            mkdir -p "$VSCODE_CONFIG_DIR"
            setup_settings_file "$VSCODE_CONFIG_DIR/settings.json" "windows"
            log_success "Linked Windows VS Code settings"
            ;;
        *)
            log_error "Unknown context: $context"
            return 1
            ;;
    esac
}

# Setup settings file with platform-specific overrides
setup_settings_file() {
    local target_file="$1"
    local platform="$2"

    local base_settings="$DOTFILES_DIR/.config/Code/User/settings.json"
    local platform_settings="$DOTFILES_DIR/.config/Code/User/settings.$platform.json"

    if [[ ! -f "$base_settings" ]]; then
        log_error "Base settings file not found: $base_settings"
        return 1
    fi

    # Check if platform-specific settings exist
    if [[ -f "$platform_settings" ]]; then
        log_info "Merging base settings with $platform-specific overrides"

        # Use jq to merge the base settings with platform-specific settings
        if check_jq; then
            jq -s '.[0] * .[1]' "$base_settings" "$platform_settings" > "$target_file"
            log_success "Merged settings for $platform"
        else
            log_warning "jq not available, copying base settings only"
            cp "$base_settings" "$target_file"
        fi
    else
        log_info "No platform-specific settings found for $platform, using base settings"
        cp "$base_settings" "$target_file"
    fi

    # Set appropriate permissions
    chmod 644 "$target_file"
}

# Backup existing settings
backup_existing_settings() {
    local target_file="$1"

    if [[ -f "$target_file" ]]; then
        local backup_file="${target_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up existing settings to: $backup_file"
        cp "$target_file" "$backup_file"
    fi
}

# Main installation function
main() {
    log_info "Starting VS Code settings installation..."

    # Detect the current context
    local context
    context="${1:-${DOTFILES_PLATFORM:-$(detect_context)}}"

    if [[ "$context" == "unknown" ]]; then
        log_error "Could not detect platform context"
        exit 1
    fi

    log_info "Detected context: $context"

    # Setup VS Code configuration
    setup_vscode "$context"

    log_success "VS Code settings installation completed successfully!"
    log_info "Settings installed for context: $context"

    # Show what was installed
    case "$context" in
        "wsl")
            log_info "Installed settings for:"
            log_info "  - VS Code Server (WSL2): ~/.vscode-server/data/Machine/settings.json"
            log_info "  - Windows VS Code (Remote-WSL): /mnt/c/Users/\$USER/AppData/Roaming/Code/User/settings.json"
            ;;
        "linux")
            log_info "Installed settings to: ~/.config/Code/User/settings.json"
            ;;
        "darwin")
            log_info "Installed settings to: ~/Library/Application Support/Code/User/settings.json"
            ;;
        "windows")
            log_info "Installed settings to: \$APPDATA/Code/User/settings.json"
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
