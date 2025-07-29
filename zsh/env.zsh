# Environment loading for zsh
#
# Load variables from the `.env` file in the dotfiles repository (if it
# exists).  Additional environment files can be loaded by setting the
# `DOTFILES_ADDITIONAL_ENV` variable before sourcing this file.  The
# `load_env_file` function is defined in scripts/load_env.sh.

if [[ -f "$HOME/dotfiles/scripts/load_env.sh" ]]; then
    # shellcheck source=dotfiles-main/scripts/load_env.sh
    . "$HOME/dotfiles/scripts/load_env.sh"
    # Load the main .env file from the root of the project
    load_env_file "$HOME/dotfiles/.env"
    # Load an additional env file if specified
    if [[ -n "$DOTFILES_ADDITIONAL_ENV" ]]; then
        load_env_file "$DOTFILES_ADDITIONAL_ENV"
    fi
fi