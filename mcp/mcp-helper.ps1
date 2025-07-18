# PowerShell helper script to generate VS Code MCP server configuration
# This script reads environment variables and generates the proper VS Code settings

param(
    [Parameter(Position=0)]
    [ValidateSet("generate", "env", "help")]
    [string]$Action = "help"
)

# Function to load MCP environment variables
function Load-McpEnvironment {
    # Handle WSL2 symlinked dotfiles - try multiple possible paths
    $possiblePaths = @(
        "$env:USERPROFILE\dotfiles\mcp\.env",           # Windows symlink
        "$env:USERPROFILE\.dotfiles\mcp\.env",          # Alternative location
        "\\wsl.localhost\Ubuntu\home\$env:USERNAME\dotfiles\mcp\.env",  # Direct WSL path
        "\\wsl$\Ubuntu\home\$env:USERNAME\dotfiles\mcp\.env"            # WSL$ path
    )
    
    $envFile = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $envFile = $path
            Write-Verbose "Found MCP environment file at: $path"
            break
        }
    }
    
    if ($envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2]
                # Remove quotes if present
                $value = $value -replace '^"(.*)"$', '$1'
                $value = $value -replace "^'(.*)'$", '$1'
                # Expand variables like $HOME - handle both Windows and WSL paths
                $value = $value -replace '\$HOME', $env:USERPROFILE
                $value = $value -replace '/home/[^/]+', $env:USERPROFILE
                # Convert WSL paths to Windows paths for Node.js compatibility
                $value = $value -replace '/home/([^/]+)/(.*)', '$env:USERPROFILE\$2'
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
    } else {
        Write-Warning "MCP environment file not found in any of the expected locations"
    }
}

# Function to generate VS Code MCP configuration
function Generate-VsCodeMcpConfig {
    Load-McpEnvironment
    
    $config = @{
        "chat.mcp.discovery.enabled" = $true
        "github.copilot.chat.mcp.servers" = @{
            "mcp-gateway" = @{
                "command" = "node"
                "args" = @([Environment]::GetEnvironmentVariable("MCP_BRIDGE_SCRIPT_PATH"))
                "env" = @{
                    "MCP_GATEWAY_URL" = [Environment]::GetEnvironmentVariable("MCP_GATEWAY_URL")
                    "MCP_ADMIN_USERNAME" = [Environment]::GetEnvironmentVariable("MCP_ADMIN_USERNAME")
                    "MCP_ADMIN_PASSWORD" = [Environment]::GetEnvironmentVariable("MCP_ADMIN_PASSWORD")
                }
            }
        }
    }
    
    $config | ConvertTo-Json -Depth 4
}

# Function to show current MCP environment
function Show-McpEnvironment {
    Load-McpEnvironment
    
    Write-Host "Current MCP Environment Variables:"
    Write-Host "MCP_GATEWAY_URL: $([Environment]::GetEnvironmentVariable('MCP_GATEWAY_URL'))"
    Write-Host "MCP_ADMIN_USERNAME: $([Environment]::GetEnvironmentVariable('MCP_ADMIN_USERNAME'))"
    Write-Host "MCP_ADMIN_PASSWORD: [REDACTED]"
    Write-Host "MCP_SERVERS_CONFIG_PATH: $([Environment]::GetEnvironmentVariable('MCP_SERVERS_CONFIG_PATH'))"
    Write-Host "MCP_BRIDGE_SCRIPT_PATH: $([Environment]::GetEnvironmentVariable('MCP_BRIDGE_SCRIPT_PATH'))"
}

# Main script logic
switch ($Action) {
    "generate" {
        Generate-VsCodeMcpConfig
    }
    "env" {
        Show-McpEnvironment
    }
    "help" {
        Write-Host "Usage: mcp-helper.ps1 {generate|env|help}"
        Write-Host "  generate - Generate VS Code MCP configuration JSON"
        Write-Host "  env      - Show current MCP environment variables"
        Write-Host "  help     - Show this help message"
    }
}
