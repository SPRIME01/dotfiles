#!/bin/bash
# Common environment variables for all shells and platforms
# Part of the modular dotfiles configuration system

# Resolve repository paths for shared tooling modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

add_path_once() {
	local dir="${1%/}"
	[[ "$1" == "/" ]] && dir="/"
	[[ -n "$dir" && -d "$dir" ]] || return 0

	local path=":${PATH}:"
	while [[ $path == *":$dir:"* ]]; do
		path="${path//:$dir:/:}"
	done
	path="${path#:}"
	path="${path%:}"

	if [[ -n "$path" ]]; then
		PATH="$dir:$path"
	else
		PATH="$dir"
	fi
	return 0
}

# Editor settings
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

# Pager settings
export PAGER="${PAGER:-less}"
export LESS="-R -X -F"

# History settings (shell-specific settings will override these)
export HISTSIZE=10000
export HISTFILESIZE=20000

# Language and locale (only set if locale is available)
if locale -a 2>/dev/null | grep -q "en_US.UTF-8"; then
	export LANG="${LANG:-en_US.UTF-8}"
	export LC_ALL="${LC_ALL:-en_US.UTF-8}"
elif locale -a 2>/dev/null | grep -q "C.UTF-8"; then
	export LANG="${LANG:-C.UTF-8}"
	export LC_ALL="${LC_ALL:-C.UTF-8}"
else
	export LANG="${LANG:-C}"
	export LC_ALL="${LC_ALL:-C}"
fi

# Development environment variables
export NODE_ENV="${NODE_ENV:-development}"

# XDG Base Directory Specification
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Path additions (platform-specific paths will be added by platform modules)
add_path_once "$HOME/.local/bin"
add_path_once "$HOME/bin"
add_path_once "$HOME/.cargo/bin"
add_path_once "$HOME/go/bin"
add_path_once "$HOME/.poetry/bin"
add_path_once "$HOME/.npm-global/bin"

# Ensure PATH is exported after mutations
export PATH

# Development tool paths
if [[ -d "$HOME/go/bin" ]]; then
	export GOPATH="$HOME/go"
fi

# Volta (Node.js toolchain manager)
if [[ -d "$HOME/.volta/bin" ]]; then
	export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
	add_path_once "$VOLTA_HOME/bin"
fi

# Color settings for various tools
export GREP_OPTIONS="--color=auto"
export CLICOLOR=1

# Load shared cross-shell tooling modules (bash/zsh compatible)
TOOLS_DIR="$SCRIPT_DIR/tools.d/sh"
if [[ -d "$TOOLS_DIR" ]]; then
	while IFS= read -r tool_script; do
		[[ -f "$tool_script" ]] || continue
		# shellcheck source=/dev/null
		. "$tool_script"
	done < <(find "$TOOLS_DIR" -maxdepth 1 -type f -name '*.sh' | sort)
fi

# Platform-specific environment variables will be loaded by platform modules
