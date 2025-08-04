# PowerShell modular integration bridge
# This script integrates the new modular system with the existing PowerShell profile

# Get the location of the dotfiles root
$DotfilesRoot = $env:DOTFILES_ROOT
if (-not $DotfilesRoot) {
    # Fallback: derive from this script's location
    $currentFilePath = $PSCommandPath
    $profileDir = Split-Path -Parent $currentFilePath
    $DotfilesRoot = Split-Path -Parent $profileDir
    $env:DOTFILES_ROOT = $DotfilesRoot
}

# Check if the new modular system is available
$ModularLoaderPath = Join-Path $DotfilesRoot "shell/loader.ps1"

if (Test-Path $ModularLoaderPath) {
    Write-Host "Loading modular PowerShell configuration..." -ForegroundColor Cyan
    
    # Load the modular system
    & $ModularLoaderPath -Verbose:$false
    
    Write-Host "Modular PowerShell configuration loaded successfully" -ForegroundColor Green
} else {
    Write-Warning "Modular PowerShell system not found at: $ModularLoaderPath"
    Write-Host "Falling back to legacy PowerShell configuration" -ForegroundColor Yellow
    
    # Fallback to some basic configurations if the modular system isn't available
    # This ensures the profile still works during transition
    
    # Basic environment variables
    if (-not $env:EDITOR) { $env:EDITOR = "code" }
    if (-not $env:PROJECTS_ROOT) { $env:PROJECTS_ROOT = Join-Path $env:USERPROFILE "Projects" }
    
    # Basic aliases
    function ll { Get-ChildItem @args }
    function .. { Set-Location .. }
    function projects { Set-Location $env:PROJECTS_ROOT }
    function dotfiles { Set-Location $env:DOTFILES_ROOT }
    
    Write-Host "Basic PowerShell configuration loaded" -ForegroundColor Yellow
}

# Export the integration status for other scripts to check
$env:MODULAR_POWERSHELL_LOADED = if (Test-Path $ModularLoaderPath) { "true" } else { "false" }
