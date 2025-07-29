# PowerShell migration script for VS Code MCP settings (WSL2-aware)
# This script handles the Windows/WSL2 path conversion for MCP configuration

param(
    [switch]$DryRun,
    [switch]$Verbose
)

# Configuration paths for Windows VS Code
$VsCodeSettingsPath = "$env:APPDATA\Code\User\settings.json"
$VsCodePreviewSettingsPath = "$env:APPDATA\Code\User\sync\settings\preview\settings.json"
$BackupDir = "$env:USERPROFILE\dotfiles\mcp\backups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Function to create backup
function New-SettingsBackup {
    param(
        [string]$FilePath,
        [string]$BackupName
    )
    
    if (Test-Path $FilePath) {
        if (!(Test-Path $BackupDir)) {
            New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        }
        
        $backupFile = "$BackupDir\${BackupName}_${Timestamp}.json"
        Copy-Item $FilePath $backupFile
        Write-Host "✅ Backup created: $backupFile" -ForegroundColor Green
        return $backupFile
    } else {
        Write-Warning "File not found: $FilePath"
        return $null
    }
}

# Function to load MCP environment for Windows
function Get-McpEnvironment {
    $envFile = "$env:USERPROFILE\dotfiles\mcp\.env"
    $envVars = @{}
    
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2]
                # Remove quotes if present
                $value = $value -replace '^"(.*)"$', '$1'
                $value = $value -replace "^'(.*)'$", '$1'
                # Convert WSL paths to Windows paths for Node.js compatibility
                $value = $value -replace '/home/sprime01/', "$env:USERPROFILE\"
                $value = $value -replace '\$HOME', $env:USERPROFILE
                $envVars[$name] = $value
            }
        }
    }
    
    return $envVars
}

# Function to update VS Code settings
function Update-VsCodeSettings {
    param(
        [string]$FilePath,
        [string]$Description,
        [hashtable]$McpEnv
    )
    
    if (!(Test-Path $FilePath)) {
        Write-Warning "Settings file not found: $FilePath"
        return
    }
    
    Write-Host "🔧 Updating $Description..." -ForegroundColor Cyan
    
    # Create backup
    $backup = New-SettingsBackup -FilePath $FilePath -BackupName ($Description -replace '\s+', '_')
    
    if (!$DryRun) {
        try {
            # Read current settings
            $settings = Get-Content $FilePath -Raw | ConvertFrom-Json
            
            # Update MCP configuration
            $settings | Add-Member -NotePropertyName "chat.mcp.discovery.enabled" -NotePropertyValue $true -Force
            
            $mcpServers = @{
                "mcp-gateway" = @{
                    "command" = "node"
                    "args" = @($McpEnv["MCP_BRIDGE_SCRIPT_PATH"])
                    "env" = @{
                        "MCP_GATEWAY_URL" = $McpEnv["MCP_GATEWAY_URL"]
                        "MCP_ADMIN_USERNAME" = $McpEnv["MCP_ADMIN_USERNAME"]
                        "MCP_ADMIN_PASSWORD" = $McpEnv["MCP_ADMIN_PASSWORD"]
                    }
                }
            }
            
            $settings | Add-Member -NotePropertyName "github.copilot.chat.mcp.servers" -NotePropertyValue $mcpServers -Force
            
            # Write updated settings
            $settings | ConvertTo-Json -Depth 10 | Set-Content $FilePath
            Write-Host "✅ Updated $Description successfully" -ForegroundColor Green
            
        } catch {
            Write-Error "Failed to update $Description : $($_.Exception.Message)"
            if ($backup) {
                Write-Host "💡 Restoring from backup..." -ForegroundColor Yellow
                Copy-Item $backup $FilePath
            }
        }
    } else {
        Write-Host "🔍 DRY RUN: Would update $Description" -ForegroundColor Yellow
    }
}

# Main script
Write-Host "🚀 Starting WSL2-aware VS Code MCP settings migration..." -ForegroundColor Cyan

# Load MCP environment
$mcpEnv = Get-McpEnvironment

if ($mcpEnv.Count -eq 0) {
    Write-Error "No MCP environment variables found. Please check your MCP .env file."
    exit 1
}

Write-Host "📋 MCP Environment loaded:" -ForegroundColor Green
$mcpEnv.GetEnumerator() | ForEach-Object {
    if ($_.Name -like "*PASSWORD*") {
        Write-Host "  $($_.Name): [REDACTED]" -ForegroundColor Gray
    } else {
        Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor Gray
    }
}

# Update settings files
Update-VsCodeSettings -FilePath $VsCodeSettingsPath -Description "Main Settings" -McpEnv $mcpEnv
Update-VsCodeSettings -FilePath $VsCodePreviewSettingsPath -Description "Preview Settings" -McpEnv $mcpEnv

Write-Host "🎉 Migration complete!" -ForegroundColor Green
Write-Host "📁 Backups stored in: $BackupDir" -ForegroundColor Cyan
Write-Host "🔄 Please restart VS Code to apply the changes." -ForegroundColor Yellow
