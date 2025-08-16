#!/usr/bin/env bash
# Install or update oh-my-posh with optional checksum verification.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="${OMP_BIN:-$HOME/.local/bin}"
BIN_PATH="${OMP_BIN_PATH:-$BIN_DIR/oh-my-posh}"
TARGET_VERSION="${OMP_VERSION:-}" # empty means latest behavior from upstream
EXPECTED_SHA256="${OMP_EXPECTED_SHA256:-}"
LOCAL_FILE="${OMP_LOCAL_FILE:-}"
BINARY_NAME="oh-my-posh"

# logging helper
if [[ -f "$ROOT_DIR/lib/log.sh" ]]; then
	# shellcheck disable=SC1090
	. "$ROOT_DIR/lib/log.sh"
fi
log_info() { echo "[INFO ] $*"; }
log_warn() { echo "[WARN ] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

verify_checksum() {
	local file="$1" expected="$2"
	if [[ -z "$expected" ]]; then
		log_warn "No expected checksum provided; skipping verification"
		return 0
	fi
	local actual=""
	if command -v sha256sum >/dev/null 2>&1; then
		actual=$(sha256sum "$file" | awk '{print $1}')
	elif command -v shasum >/dev/null 2>&1; then
		actual=$(shasum -a 256 "$file" | awk '{print $1}')
	else
		log_warn "No checksum tool available; skipping verification"
		return 0
	fi
	if [[ "$actual" != "$expected" ]]; then
		log_error "Checksum mismatch for $file"
		log_error "Expected: $expected"
		log_error "Actual:   $actual"
		return 1
	fi
	log_info "Checksum verified ($actual)"
}

main() {
	if [[ "${TARGET_VERSION:-}" == "skip" ]]; then
		log_info "Skipping oh-my-posh installation (OMP_VERSION=skip)"
		return 0
	fi

	mkdir -p "$(dirname "$BIN_PATH")"

	# If binary already exists and matches target, skip
	if [[ -x "$BIN_PATH" ]]; then
		if "$BIN_PATH" version 2>/dev/null | grep -q "${TARGET_VERSION:-}"; then
			log_info "oh-my-posh already at ${TARGET_VERSION}; skipping"
			return 0
		fi
	fi

	log_info "Installing oh-my-posh -> ${BIN_PATH}"
	local tmpfile
	tmpfile=$(mktemp)
	trap 'rm -f "$tmpfile"' EXIT

	if [[ -n "$LOCAL_FILE" && -f "$LOCAL_FILE" ]]; then
		log_info "Using local file $LOCAL_FILE"
		cp "$LOCAL_FILE" "$tmpfile"
	else
		local url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/download/${TARGET_VERSION:-latest}/posh-linux-amd64"
		log_info "Downloading $url"
		curl -fsSL "$url" -o "$tmpfile"
	fi

	verify_checksum "$tmpfile" "$EXPECTED_SHA256"
	chmod +x "$tmpfile"
	mv "$tmpfile" "$BIN_PATH"
	log_info "Installed $BIN_PATH"

	"$BIN_PATH" version || true
}

main "$@"

# Ensure no stray commands after main; tmpfile is cleaned up by trap inside main
