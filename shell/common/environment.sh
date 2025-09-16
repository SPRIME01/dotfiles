#!/bin/bash
# Common environment variables for all shells and platforms
# Part of the modular dotfiles configuration system

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
if [[ -d "$HOME/.local/bin" ]]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

if [[ -d "$HOME/bin" ]]; then
	export PATH="$HOME/bin:$PATH"
fi

# Development tool paths
if [[ -d "$HOME/.cargo/bin" ]]; then
	export PATH="$HOME/.cargo/bin:$PATH"
fi

if [[ -d "$HOME/go/bin" ]]; then
	export PATH="$HOME/go/bin:$PATH"
	export GOPATH="$HOME/go"
fi

# Python development
if [[ -d "$HOME/.poetry/bin" ]]; then
	export PATH="$HOME/.poetry/bin:$PATH"
fi

# Node.js development
if [[ -d "$HOME/.npm-global/bin" ]]; then
	export PATH="$HOME/.npm-global/bin:$PATH"
fi

# Volta (Node.js toolchain manager)
if [[ -d "$HOME/.volta/bin" ]]; then
	export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
	case ":$PATH:" in
	*":$VOLTA_HOME/bin:"*) ;;
	*) export PATH="$VOLTA_HOME/bin:$PATH" ;;
	esac
fi

# Color settings for various tools
export GREP_OPTIONS="--color=auto"
export CLICOLOR=1

# Platform-specific environment variables will be loaded by platform modules
