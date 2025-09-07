#!/usr/bin/env bash
# scripts/doctor.sh - environment diagnostic helper
set -euo pipefail

# Flags (informational only; accepted for compatibility with tests)
QUICK=0
VERBOSE=0
STRICT=0
for arg in "$@"; do
	case "$arg" in
		--quick)
			QUICK=1
			;;
		--verbose)
			VERBOSE=1
			;;
		--strict)
			STRICT=1
			;;
		*)
			# ignore unknown args to keep this script forgiving
			;;
	esac
done

echo "Dotfiles Doctor"
echo "================"

# Ensure DOTFILES_ROOT for this run based on this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CANDIDATE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ -z "${DOTFILES_ROOT:-}" ]]; then
    export DOTFILES_ROOT="$CANDIDATE_ROOT"
fi

# If env-loader exists, load computed environment (PROJECTS_ROOT, etc.)
if [[ -f "$DOTFILES_ROOT/lib/env-loader.sh" ]]; then
    # shellcheck source=/dev/null
    . "$DOTFILES_ROOT/lib/env-loader.sh" 2>/dev/null || true
    if command -v load_dotfiles_environment >/dev/null 2>&1; then
        load_dotfiles_environment "$DOTFILES_ROOT" || true
    fi
fi

# Basic checks
fail=0

log() {
	# Only print debug lines when verbose
	if [[ $VERBOSE -eq 1 ]]; then
		printf '[debug] %s\n' "$*"
	fi
}

check() {
	local label="$1"; shift
	local cmd="$*"
	log "check: $label -> $cmd"
	if eval "$cmd" >/dev/null 2>&1; then
		printf '✅ %s\n' "$label"
	else
		printf '❌ %s\n' "$label"
		fail=1
	fi
}

# Optional check (does not affect overall failure)
check_optional() {
	local label="$1"; shift
	local cmd="$*"
	log "check_optional: $label -> $cmd"
	if eval "$cmd" >/dev/null 2>&1; then
		printf '✅ %s\n' "$label"
	else
		printf '⚠️  %s (optional)\n' "$label"
	fi
}

# Core environment checks
check "DOTFILES_ROOT set" test -n "${DOTFILES_ROOT:-}"
check "Home writable" test -w "$HOME"
check "Projects dir present" test -d "${PROJECTS_ROOT:-$HOME/projects}"
check_optional "Oh My Posh binary" command -v oh-my-posh

# Git global ignore checks (optional and non-fatal)
check_optional "Git installed" command -v git
check_optional "~/.gitignore_global exists" test -f "$HOME/.gitignore_global"
check_optional "Git core.excludesfile set" git config --global --get core.excludesfile
check_optional "core.excludesfile points to ~/.gitignore_global" "[[ \"$(git config --global --get core.excludesfile 2>/dev/null || true)\" == \"$HOME/.gitignore_global\" ]]"

if [ "$fail" -eq 0 ]; then
    echo "All basic checks passed"
else
    echo "Some checks failed" >&2
    if [[ $VERBOSE -eq 1 ]]; then
        echo "--- Debug Info ---" >&2
        echo "DOTFILES_ROOT=${DOTFILES_ROOT:-} (expected repo root near scripts/)" >&2
        echo "Resolved from: $CANDIDATE_ROOT" >&2
        echo "HOME=$HOME (writable? $([[ -w "$HOME" ]] && echo yes || echo no))" >&2
        echo "HOME perms: $(ls -ld "$HOME" 2>/dev/null || echo 'n/a')" >&2
        echo "PROJECTS_ROOT=${PROJECTS_ROOT:-$HOME/projects}" >&2
        echo "PROJECTS exists? $(test -d "${PROJECTS_ROOT:-$HOME/projects}" && echo yes || echo no)" >&2
    fi
fi

# Default behavior: informational exit (always 0). Use --strict to return non-zero on failures.
if [[ $STRICT -eq 1 ]]; then
    exit "$fail"
else
    exit 0
fi
