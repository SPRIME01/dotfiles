#!/usr/bin/env bash
# Common direnv integration for bash and zsh
# Safely enable direnv if installed; noop otherwise.

# Guard against multiple sourcing
if [[ -n "${DOTFILES_DIRENV_INITIALIZED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
export DOTFILES_DIRENV_INITIALIZED=1

enable_direnv() {
  # Respect opt-out
  if [[ "${DISABLE_DIRENV:-}" == "1" ]]; then
    return 0
  fi
  if command -v direnv >/dev/null 2>&1; then
    # Detect shell
    local shell_type
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      shell_type="zsh"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
      shell_type="bash"
    else
      shell_type="bash"
    fi
    eval "$(direnv hook ${shell_type})"
    export DIRENV_LOG_FORMAT=""
  fi
}

enable_direnv

# Toggle helpers (quiet by default, but user can switch temporarily)
direnv_quiet() {
  export DIRENV_LOG_FORMAT=""
  echo "direnv logging silenced (DIRENV_LOG_FORMAT set to empty string)"
}

direnv_verbose() {
  # Use default format if available (omit setting for default) else fallback
  unset DIRENV_LOG_FORMAT || true
  echo "direnv logging enabled (DIRENV_LOG_FORMAT unset)"
}

direnv_status() {
  if ! command -v direnv >/dev/null 2>&1; then
    echo "direnv not installed"
    return 1
  fi
  command direnv status 2>/dev/null | sed -e 's/^/direnv: /'
}
