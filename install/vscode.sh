#!/usr/bin/env bash

# VS Code settings installer (idempotent merge using jq)
# - Merges repo settings into user settings, preserving existing keys
#   and overriding with repo values where defined
# - Provides functions used by tests: detect_context, setup_settings_file

# Determine repo root (one level up from this script)
__script_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd; }
DOTFILES_ROOT="$(cd "$(__script_dir)/.." && pwd)"

# Optional state management integration
if [[ -f "$DOTFILES_ROOT/lib/state-management.sh" ]]; then
  # shellcheck disable=SC1090
  . "$DOTFILES_ROOT/lib/state-management.sh"
fi

command_exists() { command -v "$1" >/dev/null 2>&1; }

# Detect execution context: linux | wsl | darwin | windows | unknown
detect_context() {
  # WSL first (it can present as linux)
  if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    echo "wsl"
    return 0
  fi

  case "${OSTYPE:-}" in
    linux* ) echo "linux" ;;
    darwin* ) echo "darwin" ;;
    msys*|cygwin*|win* ) echo "windows" ;;
    * ) echo "unknown" ;;
  esac
}

ensure_dir() {
  mkdir -p "$1" || return 1
}

require_jq() {
  if ! command_exists jq; then
    echo "Error: jq is required but not installed" >&2
    return 1
  fi
}

# Merge JSON objects with repo values overriding existing values.
# Usage: merge_json_files <existing.json|-> <repo_base.json|-> <repo_overlay.json|-> > out.json
merge_json_files() {
  jq -s 'reduce .[] as $x ({}; . * $x)' "$@"
}

# Create or update a settings.json at the given target path using repo base and
# platform overlay (settings.<context>.json). Creates parent dirs as needed.
# Arguments:
#   $1 = target settings.json path (e.g., $HOME/.config/Code/User/settings.json)
#   $2 = context (linux|wsl|darwin|windows)
setup_settings_file() {
  local target_path="$1"
  local context="$2"

  require_jq || return 1

  # Source files in repo
  local base_dir="$DOTFILES_ROOT/.config/Code/User"
  local base_json="$base_dir/settings.json"
  local overlay_json="$base_dir/settings.$context.json"

  # Fallbacks if files are missing
  local base_input
  local overlay_input
  if [[ -f "$base_json" ]]; then
    base_input="$base_json"
  else
    base_input=<(echo '{}')
  fi
  if [[ -f "$overlay_json" ]]; then
    overlay_input="$overlay_json"
  else
    overlay_input=<(echo '{}')
  fi

  # Existing user settings (if any)
  local existing_input
  if [[ -s "$target_path" ]]; then
    existing_input="$target_path"
  else
    existing_input=<(echo '{}')
  fi

  # Ensure directory exists
  ensure_dir "$(dirname "$target_path")" || return 1

  # Backup existing once per run (if present)
  if [[ -f "$target_path" ]]; then
    cp -f "$target_path" "${target_path}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  fi

  # Merge: existing <- base <- overlay (repo overrides existing where defined)
  if ! merge_json_files "$existing_input" "$base_input" "$overlay_input" >"$target_path"; then
    echo "Error: failed to merge/write $target_path" >&2
    return 1
  fi

  return 0
}

# Install into the default user location for the detected context
install_vscode_settings() {
  local ctx
  ctx="$(detect_context)"
  if [[ -z "$ctx" || "$ctx" == "unknown" ]]; then
    echo "Warning: unknown environment; defaulting to linux paths" >&2
    ctx="linux"
  fi

  # Default to Linux/WSL path per request
  local user_dir="$HOME/.config/Code/User"

  # Install/merge settings.json
  if ! setup_settings_file "$user_dir/settings.json" "$ctx"; then
    return 1
  fi

  # Also configure VS Code Server machine settings for Linux/WSL environments
  # This enables Remote-SSH/WSL remote contexts to pick up settings.
  # Handle stable + insiders + (optional) VSCodium server directories.
  if [[ "$ctx" == "linux" || "$ctx" == "wsl" ]]; then
    local server_variants=(".vscode-server" ".vscode-server-insiders" ".vscodium-server")
    local variant
    for variant in "${server_variants[@]}"; do
      local server_machine_dir="$HOME/$variant/data/Machine"
      local server_settings="$server_machine_dir/settings.json"
      ensure_dir "$server_machine_dir" || return 1
      if ! setup_settings_file "$server_settings" "$ctx"; then
        echo "Error: failed to install server settings for $variant" >&2
        return 1
      fi
    done
  fi

  return 0
}

main() {
  # Do not leak shell options when sourced
  set -euo pipefail

  if install_vscode_settings; then
    # Update state if available
    if type mark_component_installed >/dev/null 2>&1; then
      mark_component_installed "vscode_settings"
    fi
    exit 0
  else
    if type mark_component_failed >/dev/null 2>&1; then
      mark_component_failed "vscode_settings" "installer error"
    fi
    exit 1
  fi
}

# Execute only when run directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
