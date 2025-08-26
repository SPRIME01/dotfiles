#!/bin/bash
# Helper script to generate VS Code MCP server configuration
# This script reads environment variables and generates the proper VS Code settings

# Source MCP environment if available
if [ -f "$HOME/dotfiles/mcp/.env" ]; then
	# shellcheck source=mcp/.env
	source "$HOME/dotfiles/mcp/.env"
fi

# Function to generate VS Code MCP configuration
generate_vscode_mcp_config() {
	cat <<EOF
{
  "chat.mcp.discovery.enabled": true,
  "github.copilot.chat.mcp.servers": {
    "mcp-gateway": {
      "command": "node",
      "args": ["${MCP_BRIDGE_SCRIPT_PATH}"],
      "env": {
        "MCP_GATEWAY_URL": "${MCP_GATEWAY_URL}",
        "MCP_ADMIN_USERNAME": "${MCP_ADMIN_USERNAME}",
        "MCP_ADMIN_PASSWORD": "${MCP_ADMIN_PASSWORD}"
      }
    }
  }
}
EOF
}

# Function to show current MCP environment
show_mcp_env() {
	echo "Current MCP Environment Variables:"
	echo "MCP_GATEWAY_URL: $MCP_GATEWAY_URL"
	echo "MCP_ADMIN_USERNAME: $MCP_ADMIN_USERNAME"
	echo "MCP_ADMIN_PASSWORD: [REDACTED]"
	echo "MCP_SERVERS_CONFIG_PATH: $MCP_SERVERS_CONFIG_PATH"
	echo "MCP_BRIDGE_SCRIPT_PATH: $MCP_BRIDGE_SCRIPT_PATH"
}

# Main script logic
case "${1:-help}" in
"generate")
	generate_vscode_mcp_config
	;;
"env")
	show_mcp_env
	;;
"help" | *)
	echo "Usage: $0 {generate|env|help}"
	echo "  generate - Generate VS Code MCP configuration JSON"
	echo "  env      - Show current MCP environment variables"
	echo "  help     - Show this help message"
	;;
esac
