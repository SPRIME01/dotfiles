#!/bin/bash
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
exec node "/home/sprime01/Projects/MCPContextForge/scripts/mcp_stdio_bridge.js"
