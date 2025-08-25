# PowerShell modular configuration loader
# Part of the modular dotfiles configuration system
# This script loads PowerShell configuration in a modular way

param(
    [switch]$Verbose
)

# Get the directory where this script is located
$ShellConfigRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Determine current platform
$CurrentPlatform = if ($IsWindows) { "windows" } elseif ($IsLinux) { "linux" } elseif ($IsMacOS) { "macos" } else { "unknown" }

# Function to safely source a PowerShell file
function Import-ConfigFile {
    param(
        [string]$FilePath,
        [string]$Description = "configuration"
    )

    if (Test-Path $FilePath) {
        if ($Verbose) {
            Write-Host "Loading $Description from: $FilePath" -ForegroundColor Cyan
        }
        . $FilePath
        return $true
    } else {
        Write-Warning "Could not load $Description from: $FilePath"
        return $false
    }
}

# Load modular configuration
if ($Verbose) {
    Write-Host "Loading modular PowerShell configuration..." -ForegroundColor Green
}

# 1. Load common environment variables (PowerShell equivalent)
$commonEnvPath = Join-Path $ShellConfigRoot "common/environment.ps1"
[void](Import-ConfigFile -FilePath $commonEnvPath -Description "common environment")

# 2. Load common aliases (PowerShell equivalent)
$commonAliasPath = Join-Path $ShellConfigRoot "common/aliases.ps1"
[void](Import-ConfigFile -FilePath $commonAliasPath -Description "common aliases")

# 3. Load common functions (PowerShell equivalent)
$commonFunctionsPath = Join-Path $ShellConfigRoot "common/functions.ps1"
[void](Import-ConfigFile -FilePath $commonFunctionsPath -Description "common functions")

# 4. Load platform-specific configuration
if ($CurrentPlatform -ne "unknown") {
    $platformConfigPath = Join-Path $ShellConfigRoot "platform-specific/$CurrentPlatform.ps1"
    [void](Import-ConfigFile -FilePath $platformConfigPath -Description "platform-specific configuration")
} else {
    Write-Warning "Unknown platform, skipping platform-specific configuration"
}

# 5. Load PowerShell-specific configuration
$psConfigPath = Join-Path $ShellConfigRoot "powershell/config.ps1"
[void](Import-ConfigFile -FilePath $psConfigPath -Description "PowerShell-specific configuration")

# Export variables for use by other scripts
$env:SHELL_CONFIG_ROOT = $ShellConfigRoot
$env:CURRENT_PLATFORM = $CurrentPlatform

if ($Verbose) {
    Write-Host "Modular PowerShell configuration loaded (platform: $CurrentPlatform)" -ForegroundColor Green
}
