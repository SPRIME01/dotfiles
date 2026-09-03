# How-To: Configure and Test Model Context Protocol (MCP)

> **Type:** Diátaxis How-To Guide (Goal-oriented, practical task)  
> **Goal:** Connect your shell environment and VS Code to an MCP gateway for AI assistant context  
> **Prerequisites:** Node.js installed; `mcp/` directory present in repository  

---

## 1. Setup the Environment

Copy the template environment configuration:
```bash
cp mcp/.env.template mcp/.env
chmod 600 mcp/.env
```

Open `mcp/.env` in your editor and configure the gateway parameters:
```bash
MCP_GATEWAY_URL="http://localhost:3000/sse"
MCP_ADMIN_USERNAME="admin"
MCP_ADMIN_PASSWORD="your-secure-password"
MCP_BRIDGE_SCRIPT_PATH="/home/sprime01/dotfiles/mcp/mcp_stdio_bridge.js"
```

---

## 2. Verify the MCP Environment

Run the MCP inspection helper:
```bash
bash mcp/mcp-helper.sh env
```
In PowerShell 7:
```powershell
.\mcp\mcp-helper.ps1 env
```

---

## 3. Merging Settings into VS Code

To make the MCP servers accessible to VS Code:
```bash
bash mcp/migrate-vscode-settings.sh
```
In PowerShell 7:
```powershell
.\mcp\migrate-vscode-settings.ps1
```
*What this does:* Safely reads `mcp/servers.json`, resolves environment tokens, and merges the server configurations into your active VS Code `settings.json` without overwriting other editor preferences.

---

## 4. Testing the Integration

Run the integration test suite:
```bash
bash mcp/test-mcp-integration.sh
```
Or execute the automated regression test:
```bash
bash test/test-mcp-idempotent.sh
```

---

## 5. Source Trail
- `mcp/servers.json`
- `mcp/mcp-helper.sh`
- `mcp/migrate-vscode-settings.sh`
- `test/test-mcp-idempotent.sh`
