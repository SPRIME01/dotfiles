# ============================================================================
# Powerlevel10k Virtual Environment Configuration
# ============================================================================
# Source this file from ~/.p10k.zsh by adding at the end:
#   [[ -f ~/dotfiles/.p10k_virtualenv.zsh ]] && source ~/dotfiles/.p10k_virtualenv.zsh
# ============================================================================

# Ensure virtualenv segment is in the left prompt
# This adds it if not already present
typeset -ga POWERLEVEL9K_LEFT_PROMPT_ELEMENTS
if [[ ! " ${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[*]} " =~ " virtualenv " ]]; then
    # Insert virtualenv before vcs or prompt_char if they exist, otherwise append
    local -a new_elements=()
    local inserted=0
    for elem in "${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[@]}"; do
        if [[ "$elem" == "vcs" || "$elem" == "prompt_char" ]] && (( !inserted )); then
            new_elements+=(virtualenv)
            inserted=1
        fi
        new_elements+=("$elem")
    done
    if (( !inserted )); then
        new_elements+=(virtualenv)
    fi
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=("${new_elements[@]}")
fi

# ============================================================================
# Virtual Environment Display Settings
# ============================================================================

# Don't show Python version, just the venv name
typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false

# Classic parentheses style: (venv_name)
typeset -g POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER='('
typeset -g POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER=')'

# No icon, just the parentheses
typeset -g POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=''

# Color: 208 = orange, 37 = cyan, 40 = green
typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=208

# ============================================================================
# Optional: pyenv, conda, and other Python environment managers
# ============================================================================

# Uncomment to also show pyenv environments
# typeset -g POWERLEVEL9K_PYENV_FOREGROUND=37
# typeset -g POWERLEVEL9K_PYENV_VISUAL_IDENTIFIER_EXPANSION='🐍'

# Uncomment to show conda environments
# typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=70
# typeset -g POWERLEVEL9K_ANACONDA_VISUAL_IDENTIFIER_EXPANSION='🐍'
