# Managed by chezmoi - Simplified Zsh configuration
# Optimized for speed and stability

# ============================================================================
# Powerlevel10k Instant Prompt (Must be first)
# ============================================================================

# Suppress P10k instant prompt console output warnings
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# Core Initialization (Simplified, crash-resistant)
# ============================================================================

# Use simplified shell init instead of complex .shell_common.sh
if [[ -f "$HOME/dotfiles/.shell_init.sh" ]]; then
    source "$HOME/dotfiles/.shell_init.sh"
elif [[ -f "$HOME/dotfiles/.shell_init.sh" ]]; then
    source "$HOME/dotfiles/.shell_init.sh"
fi

# ============================================================================
# Oh My Zsh Configuration
# ============================================================================

# Path to Oh My Zsh installation
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (optimized for productivity)
plugins=(
    git
    direnv
    mise
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    extract
    sudo
    colored-man-pages
    command-not-found
)

# Load Oh My Zsh (with error handling)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh" 2>/dev/null || true
fi

# ============================================================================
# Zsh Options (Disable Spell Check)
# ============================================================================

# Disable command autocorrection (no "did you mean" prompts)
unsetopt CORRECT
unsetopt CORRECT_ALL

# Enable case-insensitive completion (optional, but useful)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ============================================================================
# Powerlevel10k Configuration
# ============================================================================

# Load P10k config if it exists
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Load P10k virtualenv customizations (Python venv indicator)
[[ -f ~/dotfiles/.p10k_virtualenv.zsh ]] && source ~/dotfiles/.p10k_virtualenv.zsh

# ============================================================================
# Platform-Specific Configuration
# ============================================================================

# WSL-specific configuration
export IS_WSL=1

# WSL PATH additions
if [[ -d "/mnt/c/Windows/System32" ]]; then
    export PATH="$PATH:/mnt/c/Windows/System32"
fi

# Convenience alias
if command -v cmd.exe > /dev/null 2>&1; then
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
    [[ -n "$WIN_USER" ]] && alias winhome="cd /mnt/c/Users/$WIN_USER"
fi

# ============================================================================
# Zsh Enhancements (History, Completions, Aliases, Tools)
# ============================================================================

# Load enhancements from dotfiles directory
if [[ -f "$HOME/dotfiles/.zsh_enhancements.zsh" ]]; then
    source "$HOME/dotfiles/.zsh_enhancements.zsh"
elif [[ -f "$HOME/dotfiles/.zsh_enhancements.zsh" ]]; then
    source "$HOME/dotfiles/.zsh_enhancements.zsh"
fi

# ============================================================================
# Local Customizations
# ============================================================================

# Load local customizations (not managed by chezmoi)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# ============================================================================
# Performance Profiling (Optional)
# ============================================================================

if [[ "${DOTFILES_PROFILE:-}" == "1" ]]; then
    zmodload zsh/zprof
    zprof
fi


# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ============================================================================
# VibesPro mise/devbox Integration (auto-generated)
# This ensures mise-managed tools are available to all processes including
# VS Code extensions like Nx Console
# ============================================================================
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
