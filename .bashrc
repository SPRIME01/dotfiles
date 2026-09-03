# ~/.bashrc: executed by bash(1) for non-login shells.
# Sourced by ~/.profile for login shells as well.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Determine DOTFILES_ROOT
if [[ -z "${DOTFILES_ROOT:-}" ]]; then
    if [[ -d "$HOME/dotfiles" && ( -f "$HOME/dotfiles/.shell_common.sh" || -f "$HOME/dotfiles/.shell_init.sh" ) ]]; then
        DOTFILES_ROOT="$HOME/dotfiles"
    else
        DOTFILES_ROOT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" 2>/dev/null && pwd)"
    fi
fi
export DOTFILES_ROOT

# Source shared shell configuration and environment
if [[ -f "$DOTFILES_ROOT/.shell_common.sh" ]]; then
    source "$DOTFILES_ROOT/.shell_common.sh"
elif [[ -f "$DOTFILES_ROOT/.shell_init.sh" ]]; then
    source "$DOTFILES_ROOT/.shell_init.sh"
fi

# Initialize Starship prompt if available (if not already hooked by modular config)
if command -v starship >/dev/null 2>&1 && ! declare -F starship_precmd >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Cleanup Zone.Identifier files (WSL artifact cleanup)
alias rzi='find . -type f -name "*:Zone.Identifier" -delete'

# Source local overrides if present
[[ -f "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
