# UX Enhancements
oh-my-posh init pwsh | Invoke-Expression
Import-Module -Name Terminal-Icons  # Adds icons to file listings

# Check if PSReadLine is already loaded before importing
if (-not (Get-Module -Name PSReadLine)) {
    Import-Module PSReadLine            # Enhances command-line editing
}

# Load all modules from dotfiles/PowerShell/Modules
$dotfilesModules = "$HOME/dotfiles/PowerShell/Modules"
if (Test-Path $dotfilesModules) {
    Get-ChildItem -Path $dotfilesModules -Directory | ForEach-Object {
        $moduleName = $_.Name
        $moduleFile = Join-Path $_.FullName "$moduleName.psm1"
        if (Test-Path $moduleFile) {
            Import-Module $moduleFile -Force
        }
    }
}

Write-Host "📦 Importing module: $moduleName"
