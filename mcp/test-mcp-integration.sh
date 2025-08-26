#!/bin/bash
# Quick test script to verify MCP integration

echo "🧪 Testing MCP Integration..."

# Test 1: Check if MCP environment file exists
echo "📋 Test 1: MCP environment file"
if [ -f "$HOME/dotfiles/mcp/.env" ]; then
	echo "✅ MCP environment file found"
else
	echo "❌ MCP environment file not found"
	exit 1
fi

# Test 2: Check if shell common file sources MCP
echo "📋 Test 2: Shell integration"
if grep -q "MCP_ENV_PATH" "$HOME/dotfiles/.shell_common.sh"; then
	echo "✅ Shell integration configured"
else
	echo "❌ Shell integration not configured"
	exit 1
fi

# Test 3: Source environment and check variables
echo "📋 Test 3: Environment variables"
# shellcheck source=mcp/.env
source "$HOME/dotfiles/mcp/.env"

if [ -n "$MCP_GATEWAY_URL" ]; then
	echo "✅ MCP_GATEWAY_URL: $MCP_GATEWAY_URL"
else
	echo "❌ MCP_GATEWAY_URL not set"
	exit 1
fi

if [ -n "$MCP_ADMIN_USERNAME" ]; then
	echo "✅ MCP_ADMIN_USERNAME: $MCP_ADMIN_USERNAME"
else
	echo "❌ MCP_ADMIN_USERNAME not set"
	exit 1
fi

if [ -n "$MCP_BRIDGE_SCRIPT_PATH" ]; then
	echo "✅ MCP_BRIDGE_SCRIPT_PATH: $MCP_BRIDGE_SCRIPT_PATH"
else
	echo "❌ MCP_BRIDGE_SCRIPT_PATH not set"
	exit 1
fi

# Test 4: Check if bridge script exists
echo "📋 Test 4: Bridge script"
if [ -f "$MCP_BRIDGE_SCRIPT_PATH" ]; then
	echo "✅ Bridge script found"
else
	echo "⚠️  Bridge script not found at: $MCP_BRIDGE_SCRIPT_PATH"
	echo "💡 This is expected if MCPContextForge is not set up yet"
fi

# Test 5: Check helper scripts
echo "📋 Test 5: Helper scripts"
if [ -f "$HOME/dotfiles/mcp/mcp-helper.sh" ]; then
	echo "✅ Bash helper script found"
else
	echo "❌ Bash helper script not found"
fi

if [ -f "$HOME/dotfiles/mcp/mcp-helper.ps1" ]; then
	echo "✅ PowerShell helper script found"
else
	echo "❌ PowerShell helper script not found"
fi

echo "🎉 MCP integration test complete!"
echo "💡 Run 'source ~/.bashrc' or 'source ~/.zshrc' to activate MCP environment"
