#!/bin/bash
# Migration script to update VS Code settings.json with environment-based MCP configuration
# This script will backup your current settings and update them to use environment variables

set -e

# Configuration paths
VSCODE_SETTINGS_PATH="$HOME/AppData/Roaming/Code/User/settings.json"
VSCODE_PREVIEW_SETTINGS_PATH="$HOME/AppData/Roaming/Code/User/sync/settings/preview/settings.json"
BACKUP_DIR="$HOME/dotfiles/mcp/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to create backup
create_backup() {
	local file_path="$1"
	local backup_name="$2"

	if [ -f "$file_path" ]; then
		mkdir -p "$BACKUP_DIR"
		cp "$file_path" "$BACKUP_DIR/${backup_name}_${TIMESTAMP}.json"
		echo "✅ Backup created: $BACKUP_DIR/${backup_name}_${TIMESTAMP}.json"
	else
		echo "⚠️  File not found: $file_path"
	fi
}

# Function to update settings file
update_settings_file() {
	local file_path="$1"
	local file_name="$2"

	if [ ! -f "$file_path" ]; then
		echo "⚠️  Settings file not found: $file_path"
		return 1
	fi

	# Create backup
	create_backup "$file_path" "$file_name"

	# Create temporary file with updated settings
	local temp_file=$(mktemp)

	# Use jq to update the settings (requires jq to be installed)
	if command -v jq &>/dev/null; then
		echo "🔧 Updating $file_name with environment-based MCP configuration..."

		# Read current settings and update MCP configuration
		jq '
        .["chat.mcp.discovery.enabled"] = true |
        .["github.copilot.chat.mcp.servers"] = {
            "mcp-gateway": {
                "command": "node",
                "args": [env.MCP_BRIDGE_SCRIPT_PATH // "/home/sprime01/Projects/MCPContextForge/scripts/mcp_stdio_bridge.js"],
                "env": {
                    "MCP_GATEWAY_URL": env.MCP_GATEWAY_URL // "http://127.0.0.1:4444",
                    "MCP_ADMIN_USERNAME": env.MCP_ADMIN_USERNAME // "sprime01",
                    "MCP_ADMIN_PASSWORD": env.MCP_ADMIN_PASSWORD // "mcp1870171sP#"
                }
            }
        }
        ' "$file_path" >"$temp_file"

		# Replace original file with updated version
		mv "$temp_file" "$file_path"
		echo "✅ Updated $file_name successfully"
	else
		echo "⚠️  jq not found. Cannot automatically update settings."
		echo "💡 Manual update required for: $file_path"
		rm "$temp_file"
	fi
}

# Main script
echo "🚀 Starting VS Code MCP settings migration..."

# Source MCP environment variables
if [ -f "$HOME/dotfiles/mcp/.env" ]; then
	# shellcheck source=mcp/.env
	source "$HOME/dotfiles/mcp/.env"
	echo "✅ MCP environment variables loaded"
else
	echo "⚠️  MCP environment file not found. Using defaults."
fi

# Update main settings file
update_settings_file "$VSCODE_SETTINGS_PATH" "settings"

# Update preview settings file
update_settings_file "$VSCODE_PREVIEW_SETTINGS_PATH" "preview_settings"

echo "🎉 Migration complete!"
echo "📁 Backups stored in: $BACKUP_DIR"
echo "🔄 Please restart VS Code to apply the changes."
