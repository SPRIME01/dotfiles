#!/usr/bin/env bash
# Description: Central constants and reusable default paths.
# Category: library
# Idempotent: yes
# Exports shared constants for scripts to source.

# Default locations (static constants; do not depend on current overrides)
export DOTFILES_STATE_FILE_DEFAULT="$HOME/.dotfiles-state"
export PROJECTS_ROOT_DEFAULT="$HOME/projects"

# Oh My Posh installer (update monthly or when version changes)
readonly OMP_INSTALLER_URL="https://ohmyposh.dev/install.sh"
# Note: Checksum should be updated regularly. Use: bash lib/secure-install.sh fetch_checksum
# To skip checksum verification (not recommended), set to "skip"
readonly OMP_INSTALLER_SHA256="skip"  # TODO: Fetch and update checksum
readonly OMP_UPDATE_DATE="2025-11-22"

# Functions to resolve effective paths (allow overrides)
get_state_file() { echo "${DOTFILES_STATE_FILE:-$DOTFILES_STATE_FILE_DEFAULT}"; }
get_projects_root() { echo "${PROJECTS_ROOT:-$PROJECTS_ROOT_DEFAULT}"; }
