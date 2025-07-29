# Prompt configuration for zsh
#
# This file sets the theme for Oh My Zsh.  The default theme uses
# powerlevel10k, providing consistency with Oh‑My‑Posh in PowerShell.  If
# powerlevel10k is not installed, the script falls back to the default theme.

export ZSH_THEME="powerlevel10k/powerlevel10k"

# Load Powerlevel10k configuration if present
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh