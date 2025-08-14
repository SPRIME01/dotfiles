#!/usr/bin/env bash
# Description: Bootstrap Unix shell environment (symlinks, themes, MCP, VS Code) idempotently.
# Category: setup
# Dependencies: curl (optional), bash, git
# Idempotent: yes (safe re-runs; external installers may self-skip if already present)
# Inputs: DOTFILES (path auto-detected)
# Outputs: Symlinked config files, installed themes/tools, updated editor settings
# Exit Codes: 0 success, >0 failure conditions (missing repo)
set -euo pipefail

# Logging
if [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/log.sh" ]; then
    # shellcheck disable=SC1090
    . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/log.sh"
fi

# Source platform detection helpers
if [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/platform-detection.sh" ]; then
    # shellcheck source=/dev/null
    . "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/platform-detection.sh"
    detect_platform || true
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_info "Bootstrap start: $ROOT_DIR"

# Source platform helpers if they exist
for helper in lib/platform-detection.sh lib/error-handling.sh lib/env-loader.sh; do
    if [ -f "$ROOT_DIR/$helper" ]; then
        # shellcheck disable=SC1090
        source "$ROOT_DIR/$helper"
    fi
done

# Source modular steps
if [ -f "$ROOT_DIR/lib/bootstrap/steps.sh" ]; then
    # shellcheck disable=SC1090
    source "$ROOT_DIR/lib/bootstrap/steps.sh"
else
    log_error "Missing lib/bootstrap/steps.sh; cannot continue"
    exit 1
fi

bootstrap_link_shell_configs "$ROOT_DIR"
bootstrap_install_oh_my_posh "$ROOT_DIR"
bootstrap_install_oh_my_zsh
bootstrap_zsh_linux_setup "$ROOT_DIR"
bootstrap_mcp "$ROOT_DIR"
bootstrap_vscode "$ROOT_DIR"
bootstrap_doctor "$ROOT_DIR"

log_info "Bootstrap complete"
