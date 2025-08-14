#!/usr/bin/env bash
# Description: Component registry loader using components.yaml to expose component metadata.
# Category: library
# Dependencies: awk, grep, sed
# Idempotent: yes
set -euo pipefail

REGISTRY_SOURCE="${DOTFILES_REGISTRY_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/components.yaml}"

if [[ ! -f "$REGISTRY_SOURCE" ]]; then
  echo "Registry file not found: $REGISTRY_SOURCE" >&2
  exit 1
fi

# get_component_field <component_id> <field>
get_component_field() {
  local id="$1" field="$2"
  awk -v comp="$id" -v fld="$field" '
    $1 == "-" && $2 == "id:" {current=$3}
    current==comp && $1==fld":" {sub(/^[^:]*: /,""); print; exit}
  ' "$REGISTRY_SOURCE"
}

# list_components
list_components() {
  grep -E '^  - id:' "$REGISTRY_SOURCE" | awk '{print $3}'
}

# Example usage when run directly
if [[ "${1:-}" == "--list" ]]; then
  list_components
elif [[ "${1:-}" == "--get" ]]; then
  shift
  get_component_field "$@"
fi
