#!/usr/bin/env bash
# Wrapper script to run MCP bridge with environment variables

# Source MCP environment if available
if [ -f "$HOME/dotfiles/mcp/.env" ]; then
	source "$HOME/dotfiles/mcp/.env"
	export MCP_GATEWAY_URL
	export MCP_ADMIN_USERNAME
	export MCP_ADMIN_PASSWORD
	export MCP_JWT_TOKEN
fi

# Run the MCP bridge script
BRIDGE_SCRIPT="${MCP_BRIDGE_SCRIPT_PATH:-$HOME/projects/MCPContextForge/scripts/mcp_stdio_bridge.js}"
if [[ ! -f "$BRIDGE_SCRIPT" ]]; then
	echo "Error: MCP bridge script not found at $BRIDGE_SCRIPT" >&2
	echo "Please set MCP_BRIDGE_SCRIPT_PATH in mcp/.env" >&2
	exit 1
fi
exec node "$BRIDGE_SCRIPT"
