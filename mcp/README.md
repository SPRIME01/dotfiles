# MCP (Model Context Protocol) Setup

This directory contains the MCP server configuration and environment setup for your dotfiles.

## Files

- **`.env`** - Environment variables for MCP configuration
- **`servers.json`** - MCP server definitions and configurations
- **`README.md`** - This file

## Environment Variables

The `.env` file contains:
- `MCP_GATEWAY_URL` - URL for the MCP gateway service
- `MCP_ADMIN_USERNAME` - Admin username for MCP authentication
- `MCP_ADMIN_PASSWORD` - Admin password for MCP authentication
- `MCP_SERVERS_CONFIG_PATH` - Path to the servers configuration file
- `MCP_BRIDGE_SCRIPT_PATH` - Path to the MCP stdio bridge script

## Usage

The MCP environment is automatically loaded when you start your shell through the dotfiles configuration. The environment variables are sourced from this `.env` file and made available to:

1. Shell sessions (bash/zsh)
2. VS Code MCP server configurations
3. Any MCP-aware applications

## Security Note

The `.env` file contains sensitive credentials. Ensure this file has appropriate permissions and is not committed to version control if your dotfiles repo is public.
