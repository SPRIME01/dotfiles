#!/usr/bin/env bash
# lib/platform-detection.sh - OS and shell / platform detection utilities
# Description: Central utilities to detect runtime platform & provide predicate helpers.
# Category: library
# Idempotent: yes (pure detection; re-runnable)
# Dependencies: uname
# Outputs: Exports DOTFILES_PLATFORM, DOTFILES_SHELL
# Exit Codes: 0 always (functions return 0/1)
# Exit Codes: 0 always (functions return 0/1)
# NOTE: This file is intended to be sourced. Avoid forcing strict mode globally.
# Enable strict mode only if executed directly.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	set -euo pipefail
fi

detect_platform() {
	# Only compute once per shell session unless forced
	if [[ -n "${DOTFILES_PLATFORM:-}" && "${1:-}" != "--force" ]]; then
		return 0
	fi

	local uname_s
	uname_s="$(uname -s 2>/dev/null || echo unknown)"
	local platform="unknown"
	case "$uname_s" in
	Linux*) platform="linux" ;;
	Darwin*) platform="macos" ;;
	CYGWIN*) platform="windows" ;;
	MINGW*) platform="windows" ;;
	MSYS*) platform="windows" ;;
	*) platform="unknown" ;;
	esac

	# Detect WSL (takes precedence over plain linux)
	if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
		platform="wsl"
	fi

	local shell_name
	shell_name="$(basename "${SHELL:-bash}")"

	export DOTFILES_PLATFORM="$platform"
	export DOTFILES_SHELL="$shell_name"

	if [[ "${DOTFILES_DEBUG:-}" == "true" ]]; then
		echo "[platform-detection] platform=$platform shell=$shell_name" >&2
	fi
}

# Predicate helpers (use detect_platform lazily)
is_linux() {
	detect_platform
	[[ "${DOTFILES_PLATFORM}" == "linux" ]]
}
is_macos() {
	detect_platform
	[[ "${DOTFILES_PLATFORM}" == "macos" ]]
}
is_wsl() {
	detect_platform
	[[ "${DOTFILES_PLATFORM}" == "wsl" ]]
}
is_windows() {
	detect_platform
	[[ "${DOTFILES_PLATFORM}" == "windows" ]]
}
is_unix() {
	detect_platform
	case "${DOTFILES_PLATFORM}" in linux | macos | wsl) return 0 ;; *) return 1 ;; esac
}

# Get the absolute path to dotfiles root
get_dotfiles_root() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	(cd "$script_dir/.." && pwd)
}

# Validate that dotfiles root is properly set
validate_dotfiles_root() {
	local dotfiles_root="$1"

	if [[ -z "$dotfiles_root" ]]; then
		echo "Error: DOTFILES_ROOT not provided" >&2
		return 1
	fi

	if [[ ! -d "$dotfiles_root" ]]; then
		echo "Error: DOTFILES_ROOT directory does not exist: $dotfiles_root" >&2
		return 1
	fi

	if [[ ! -f "$dotfiles_root/.shell_common.sh" ]]; then
		echo "Error: Invalid DOTFILES_ROOT - missing .shell_common.sh: $dotfiles_root" >&2
		return 1
	fi

	return 0
}
