#!/usr/bin/env bash
# Sync dotfiles environment to systemd user environment
# Run this after updating .env files to make them available to GUI apps

set -euo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/dotfiles}"

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Syncing environment variables to systemd...${NC}"
echo ""

# Export .env file
if [[ -f "$DOTFILES_ROOT/.env" ]]; then
    bash "$DOTFILES_ROOT/scripts/export-to-systemd-env.sh" "$DOTFILES_ROOT/.env"
else
    echo "Warning: $DOTFILES_ROOT/.env not found" >&2
fi

echo ""
echo -e "${GREEN}✓ Environment synced to systemd${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart VS Code (or reload window: Ctrl+Shift+P → 'Reload Window')"
echo "  2. Your MCP servers will now have access to these variables"
echo ""
echo "To verify variables are set:"
echo "  systemctl --user show-environment | grep -E '(SMITHERY|GEMINI|YOUCOM)'"
