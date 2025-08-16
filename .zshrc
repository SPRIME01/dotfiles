# Suppress instant prompt warnings - must be set before instant prompt initialization
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# Enable Powerlevel10k instant prompt early.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# dotfiles/.zshrc — minimal, modular loader

# Resolve DOTFILES_ROOT consistently
if [[ -z ${DOTFILES_ROOT:-} ]]; then
    DOTFILES_ROOT="$HOME/dotfiles"
fi

# Always source shared configuration first
if [[ -r "$DOTFILES_ROOT/.shell_common.sh" ]]; then
    source "$DOTFILES_ROOT/.shell_common.sh"
fi

# Oh My Zsh path
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Ensure Powerlevel10k theme is selected if installed and no theme explicitly set
if [[ -z ${ZSH_THEME:-} ]]; then
    if [[ -d "${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k" ]]; then
        export ZSH_THEME="powerlevel10k/powerlevel10k"
    fi
fi

# Modular zsh configuration
[[ -r "$DOTFILES_ROOT/zsh/env.zsh" ]] && source "$DOTFILES_ROOT/zsh/env.zsh"
[[ -r "$DOTFILES_ROOT/zsh/path.zsh" ]] && source "$DOTFILES_ROOT/zsh/path.zsh"
[[ -r "$DOTFILES_ROOT/zsh/plugins.zsh" ]] && source "$DOTFILES_ROOT/zsh/plugins.zsh"
[[ -r "$DOTFILES_ROOT/zsh/prompt.zsh" ]] && source "$DOTFILES_ROOT/zsh/prompt.zsh"

# Initialize Oh My Zsh if available
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Shared functions
[[ -r "$DOTFILES_ROOT/.shell_functions.sh" ]] && source "$DOTFILES_ROOT/.shell_functions.sh"

# SSH agent bridge (WSL-aware script handles idempotency/noise)
[[ -r "$DOTFILES_ROOT/zsh/ssh-agent.zsh" ]] && source "$DOTFILES_ROOT/zsh/ssh-agent.zsh"

# Core shell options (compinit is invoked by oh-my-zsh)
setopt CORRECT
setopt EXTENDED_GLOB
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Enhanced history search keybinds if plugin is loaded
if (( $+functions[history-substring-search-up] )); then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# Preferred editor per context
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='code'
fi

# Powerlevel10k config (deferred until after oh-my-zsh loads functions)
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# Add Pulumi to PATH idempotently (only if it exists)
if [[ -d "$HOME/.pulumi/bin" ]]; then
    case ":$PATH:" in
        *":$HOME/.pulumi/bin:"*) ;;
        *) PATH="$PATH:$HOME/.pulumi/bin" ;;
    esac
    export PATH
fi

# Common user bins (~/.local/bin, ~/.cargo/bin)
for _p in "$HOME/.local/bin" "$HOME/.cargo/bin"; do
    if [[ -d "$_p" && ":$PATH:" != *":$_p:"* ]]; then
        PATH="$PATH:$_p"
    fi
done
export PATH

# Optional debug tracing
if [[ ${DOTFILES_DEBUG:-0} == 1 ]]; then
    echo "[dotfiles] zsh profile loaded (DOTFILES_ROOT=$DOTFILES_ROOT, ZSH=$ZSH)"
fi
