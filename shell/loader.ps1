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

# Load modular configuration (dot-source in this script scope so functions persist)
if ($Verbose) {
    Write-Host "Loading modular PowerShell configuration..." -ForegroundColor Green
}

# 1. Load common environment variables
$commonEnvPath = Join-Path $ShellConfigRoot "common/environment.ps1"
if (Test-Path $commonEnvPath) {
    if ($Verbose) { Write-Host "Loading common environment from: $commonEnvPath" -ForegroundColor Cyan }
    . $commonEnvPath
} else { Write-Warning "Could not load common environment from: $commonEnvPath" }

# 2. Load common aliases
$commonAliasPath = Join-Path $ShellConfigRoot "common/aliases.ps1"
if (Test-Path $commonAliasPath) {
    if ($Verbose) { Write-Host "Loading common aliases from: $commonAliasPath" -ForegroundColor Cyan }
    . $commonAliasPath
} else { Write-Warning "Could not load common aliases from: $commonAliasPath" }

# 3. Load common functions
$commonFunctionsPath = Join-Path $ShellConfigRoot "common/functions.ps1"
if (Test-Path $commonFunctionsPath) {
    if ($Verbose) { Write-Host "Loading common functions from: $commonFunctionsPath" -ForegroundColor Cyan }
    . $commonFunctionsPath
} else { Write-Warning "Could not load common functions from: $commonFunctionsPath" }

# 4. Load platform-specific configuration
if ($CurrentPlatform -ne "unknown") {
    $platformConfigPath = Join-Path $ShellConfigRoot "platform-specific/$CurrentPlatform.ps1"
    if (Test-Path $platformConfigPath) {
        if ($Verbose) { Write-Host "Loading platform-specific configuration from: $platformConfigPath" -ForegroundColor Cyan }
        . $platformConfigPath
    } else {
        Write-Warning "Could not load platform-specific configuration from: $platformConfigPath"
    }
} else {
    Write-Warning "Unknown platform, skipping platform-specific configuration"
}

# 5. Load PowerShell-specific configuration
$psConfigPath = Join-Path $ShellConfigRoot "powershell/config.ps1"
if (Test-Path $psConfigPath) {
    if ($Verbose) { Write-Host "Loading PowerShell-specific configuration from: $psConfigPath" -ForegroundColor Cyan }
    . $psConfigPath
} else { Write-Warning "Could not load PowerShell-specific configuration from: $psConfigPath" }

# Export variables for use by other scripts
$env:SHELL_CONFIG_ROOT = $ShellConfigRoot
$env:CURRENT_PLATFORM = $CurrentPlatform

if ($Verbose) {
    Write-Host "Modular PowerShell configuration loaded (platform: $CurrentPlatform)" -ForegroundColor Green
}
