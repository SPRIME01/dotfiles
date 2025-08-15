#!/usr/bin/env bash
# Description: Component registry loader using components.yaml to expose component metadata.
# Category: library
# Dependencies: awk, grep, sed
# Idempotent: yes

# When executed directly, enable strict mode; keep library-safe when sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

REGISTRY_SOURCE="${DOTFILES_REGISTRY_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/components.yaml}"

# Ensure registry exists (returns non-zero instead of exiting to allow safe sourcing)
# get_component_field <component_id> <field>
get_component_field() {
  local id="$1" field="$2"
  local out
  out="$(awk -v comp="$id" -v fld="$field" '
    $1 == "-" && $2 == "id:" {current=$3}
    current==comp && $1==fld":" {
      sub(/^[^:]*:[[:space:]]*/, ""); print; exit
    }
# list_components
list_components() {
  awk '$1 == "-" && $2 == "id:" {print $3}' "$REGISTRY_SOURCE"
}
  fi
# Example usage when run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  case "${1:-}" in
    --list)
      shift
      list_components
      ;;
    --get)
      shift
      get_component_field "$@"
      ;;
    *)
      echo "Usage: $0 --list | --get <component_id> <field>" >&2
      exit 2
      ;;
  esac
fi
  fi
  printf '%s\n' "$out"
}
get_component_field() {
  local id="$1" field="$2"
  ensure_registry || return 1
  awk -v comp="$id" -v fld="$field" '
    $1 == "-" && $2 == "id:" {current=$3}
    current==comp && $1==fld":" {sub(/^[^:]*: /,""); print; exit}
  ' "$REGISTRY_SOURCE"
}

# list_components
list_components() {
  ensure_registry || return 1
  grep -E '^  - id:' "$REGISTRY_SOURCE" | awk '{print $3}'
}

# Example usage when run directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ "${1:-}" == "--list" ]]; then
    list_components || exit 1
  elif [[ "${1:-}" == "--get" ]]; then
    shift
    ensure_registry || exit 1
    get_component_field "$@" || exit 1
  fi
fi
