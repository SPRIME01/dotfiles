#!/usr/bin/env bash
# Component registry loader: read simple YAML-like components file to expose metadata.
# This file is written to be safe when sourced and when executed directly.
set -euo pipefail

REGISTRY_SOURCE="${DOTFILES_REGISTRY_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/components.yaml}"

ensure_registry() {
	if [[ ! -f "$REGISTRY_SOURCE" ]]; then
		echo "Registry not found: $REGISTRY_SOURCE" >&2
		return 1
	fi
}

# get_component_field <component_id> <field>
get_component_field() {
	local id="$1" field="$2"
	ensure_registry || return 1
	awk -v comp="$id" -v fld="$field" '
    $1 == "-" && $2 == "id:" {current=$3}
    current==comp && $1==fld":" {sub(/^[^:]*:[[:space:]]*/, ""); print; exit}
  ' "$REGISTRY_SOURCE"
}

# list_components
list_components() {
	ensure_registry || return 1
	awk '$1 == "-" && $2 == "id:" {print $3}' "$REGISTRY_SOURCE"
}

# When run directly, provide a tiny CLI
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	case "${1:-}" in
	--list)
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
