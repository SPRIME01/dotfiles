#!/usr/bin/env bash
# Simplified, crash-resistant shell initialization
# Replaces the complex .shell_common.sh with a minimal, fast alternative

# ============================================================================
# Core Setup (No eval, no complex logic)
# ============================================================================

# Determine DOTFILES_ROOT safely (no eval)
if [[ -z "${DOTFILES_ROOT:-}" ]]; then
    # Try to find it relative to this script
    if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
        # Bash
        DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    elif [[ -n "${ZSH_VERSION:-}" ]] && [[ -n "${(%):-%x}" ]]; then
        # Zsh - use parameter expansion instead of eval
        DOTFILES_ROOT="$(cd "$(dirname "${(%):-%x}")" && pwd)"
    else
        # Fallback
        DOTFILES_ROOT="${HOME}/dotfiles"
    fi
fi
export DOTFILES_ROOT

# ============================================================================
# Essential Environment Variables
# ============================================================================

# Projects directory
export PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/projects}"

# WSL detection
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    export WSL_USER="${USER:-$(whoami 2>/dev/null || echo 'user')}"
    export IS_WSL=1
else
    export IS_WSL=0
fi

# ============================================================================
# PATH Configuration (Essential only)
# ============================================================================

# Helper to add to PATH only if not already present
__add_to_path() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    case ":$PATH:" in
        *":$dir:"*) return 0 ;;
        *) export PATH="$dir:$PATH" ;;
    esac
}

# Essential PATH entries
__add_to_path "$HOME/.local/bin"
__add_to_path "$HOME/bin"
__add_to_path "$HOME/.cargo/bin"
__add_to_path "$HOME/go/bin"

# Mise (if installed)
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
    __add_to_path "$HOME/.local/share/mise/shims"
fi

# Clean up
unset -f __add_to_path

# ============================================================================
# Environment Loading (Safe, with error handling)
# ============================================================================

__safe_load_env() {
    local env_file="$1"
    [[ -f "$env_file" ]] || return 0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue
        
        # Parse KEY=VALUE
        local key="${line%%=*}"
        local value="${line#*=}"
        
        # Validate key (alphanumeric + underscore only)
        [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        
        # Strip quotes
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        
        # Export (no eval!)
        export "$key=$value"
    done < "$env_file"
}

# Load .env files if they exist
__safe_load_env "$DOTFILES_ROOT/.env" 2>/dev/null || true
__safe_load_env "$DOTFILES_ROOT/mcp/.env" 2>/dev/null || true

# ============================================================================
# Essential Aliases
# ============================================================================

alias projects='cd "$PROJECTS_ROOT"'
alias dotfiles='git --git-dir="$DOTFILES_ROOT/.git" --work-tree="$DOTFILES_ROOT"'
alias cddot='cd "$DOTFILES_ROOT"'

# Conditional aliases
command -v code >/dev/null 2>&1 && alias pcode='code -n "$PROJECTS_ROOT"'

# ============================================================================
# Direnv Integration (Single, safe hook)
# ============================================================================

if command -v direnv >/dev/null 2>&1 && [[ "${DISABLE_DIRENV:-}" != "1" ]]; then
    # Detect shell type
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        eval "$(direnv hook zsh 2>/dev/null || true)"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        eval "$(direnv hook bash 2>/dev/null || true)"
    fi
    export DIRENV_LOG_FORMAT=""
fi

# ============================================================================
# Mise Integration (if installed)
# ============================================================================

if command -v mise >/dev/null 2>&1; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        eval "$(mise activate zsh 2>/dev/null || true)"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        eval "$(mise activate bash 2>/dev/null || true)"
    fi
fi

# ============================================================================
# Lazy Loaders (Load on demand, not at startup)
# ============================================================================

# WSL integration (lazy-loaded)
__load_wsl_integration() {
    [[ "$IS_WSL" != "1" ]] && return 0
    [[ -n "${__WSL_LOADED:-}" ]] && return 0
    
    # Source WSL-specific file if it exists
    if [[ -f "$DOTFILES_ROOT/shell/platform-specific/wsl.sh" ]]; then
        source "$DOTFILES_ROOT/shell/platform-specific/wsl.sh" 2>/dev/null || true
    fi
    
    export __WSL_LOADED=1
}

# Platform-specific (lazy-loaded)
__load_platform_config() {
    [[ -n "${__PLATFORM_LOADED:-}" ]] && return 0
    
    local platform=""
    case "$OSTYPE" in
        linux*) platform="linux" ;;
        darwin*) platform="macos" ;;
        msys*|cygwin*|mingw*) platform="windows" ;;
    esac
    
    if [[ -n "$platform" ]] && [[ -f "$DOTFILES_ROOT/shell/platform-specific/$platform.sh" ]]; then
        source "$DOTFILES_ROOT/shell/platform-specific/$platform.sh" 2>/dev/null || true
    fi
    
    export __PLATFORM_LOADED=1
}

# Auto-load WSL integration if in WSL
[[ "$IS_WSL" == "1" ]] && __load_wsl_integration

# ============================================================================
# Shell Greeting (Simple, non-crashing)
# ============================================================================

if [[ $- == *i* ]] && [[ "${TERM_PROGRAM:-}" != "vscode" ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "✨ Zsh ready"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "👋 Bash ready"
    fi
fi

# ============================================================================
# Performance Profiling (Optional)
# ============================================================================

if [[ "${DOTFILES_PROFILE:-}" == "1" ]]; then
    echo "Shell init completed in ${SECONDS}s" >&2
fi

# Clean up temporary functions
unset -f __safe_load_env
