#!/usr/bin/env bash
# Description: Central constants and reusable default paths.
# Category: library
# Idempotent: yes
# Exports shared constants for scripts to source.

# Default locations (static constants; do not depend on current overrides)
export DOTFILES_STATE_FILE_DEFAULT="$HOME/.dotfiles-state"
export PROJECTS_ROOT_DEFAULT="$HOME/projects"
# Functions to resolve effective paths (allow overrides)
get_state_file() { echo "${DOTFILES_STATE_FILE:-$DOTFILES_STATE_FILE_DEFAULT}"; }
get_projects_root() { echo "${PROJECTS_ROOT:-$PROJECTS_ROOT_DEFAULT}"; }
