# Environment loading for zsh
#
# Environment loading is now handled by .shell_common.sh using the consolidated
# secure environment loader. This file is kept for backwards compatibility
# and future zsh-specific environment configuration.

# Additional zsh-specific environment variables can be set here
# Example:
# export ZSH_CUSTOM_VAR="value"

# If you need to load additional environment files specific to zsh:
# if [[ -f "$HOME/dotfiles/lib/env-loader.sh" ]]; then
#     . "$HOME/dotfiles/lib/env-loader.sh"
#     load_env_file_secure "$HOME/dotfiles/zsh/.env" false
# fi
