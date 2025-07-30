# MCP (Model Context Protocol) Setup

This directory contains the MCP server configuration and environment setup for your dotfiles.

## Explanation

The MCP integration allows the shell environment to communicate with a local or remote MCP gateway. This enables AI models and other tools to access context from your shell, such as the current working directory, running processes, and environment variables. This is used to provide more accurate and context-aware assistance.

## How-To

### 1. Configure the MCP Environment

The primary method for setting up the MCP environment is to use the interactive setup wizard, which can be launched with the `just` command runner.

- **For Linux, macOS, or WSL:**
  ```bash
  just setup
  ```
- **For Windows (with PowerShell 7):**
  ```bash
  just setup-windows
  ```

The wizard will guide you through the process of configuring your shells and enabling MCP integration.

### 2. Manual Configuration

If you prefer to configure the MCP environment manually, follow these steps:

1.  **Copy the environment template:**
    ```bash
    cp mcp/.env.template mcp/.env
    ```
2.  **Edit the `.env` file:**
    Open `mcp/.env` in a text editor and customize the following variables:
    - `MCP_GATEWAY_URL`: The URL of your MCP gateway.
    - `MCP_ADMIN_USERNAME`: The username for the MCP gateway.
    - `MCP_ADMIN_PASSWORD`: The password for the MCP gateway.
    - `MCP_BRIDGE_SCRIPT_PATH`: The path to your `mcp_stdio_bridge.js` script.

### 3. Test the Integration

Once you have configured the environment, you can test the integration using the following `just` command:

```bash
just test
```

This will run a series of checks to ensure that the MCP environment is loaded correctly and that the necessary scripts are in place.

## Reference

### Environment Variables

The following environment variables are used to configure the MCP integration. They are defined in the `mcp/.env` file.

-   `MCP_GATEWAY_URL`: The URL of the MCP gateway service.
-   `MCP_ADMIN_USERNAME`: The admin username for MCP authentication.
-   `MCP_ADMIN_PASSWORD`: The admin password for MCP authentication.
-   `MCP_SERVERS_CONFIG_PATH`: The path to the `servers.json` file, which defines the MCP server configurations.
-   `MCP_BRIDGE_SCRIPT_PATH`: The path to the `mcp_stdio_bridge.js` script, which is used to communicate with the MCP gateway.
-   `MCP_DEBUG`: (Optional) Set to `true` to enable debug logging.
-   `MCP_LOG_LEVEL`: (Optional) The log level for the MCP integration.

### `just` Commands

-   `just setup`: Launch the interactive setup wizard for Unix-like shells.
-   `just setup-windows`: Launch the interactive setup wizard for Windows PowerShell.
-   `just test`: Run automated tests to verify the dotfiles configuration, including the MCP integration.

## Security Note

The `.env` file contains sensitive credentials. Ensure this file has appropriate permissions and is not committed to version control if your dotfiles repo is public.