$dotfiles = "$PSScriptRoot"

Write-Host "🔧 Setting up PowerShell environment..."

$dotfiles = "$HOME\dotfiles"
if ($IsWindows) {
    $profileDir = "$HOME\Documents\PowerShell"
}
else {
    $profileDir = "$HOME/.config/powershell"
}
$configFileTarget = Join-Path $profileDir "powershell.config.json"
$configFileSource = Join-Path $dotfiles "PowerShell\powershell.config.json"

# Ensure PowerShell profile directory exists
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Symlink PowerShell profile
$profileSource = Join-Path $dotfiles "PowerShell\Microsoft.PowerShell_profile.ps1"
$profileTarget = Join-Path $profileDir "Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $profileTarget)) {
    New-Item -ItemType SymbolicLink -Path $profileTarget -Target $profileSource -Force | Out-Null
    Write-Host "🔗 Linked PowerShell profile"
}
else {
    Write-Host "✅ PowerShell profile already linked"
}

# Copy or link powershell.config.json
if (Test-Path $configFileSource) {
    if (-not (Test-Path $configFileTarget)) {
        try {
            New-Item -ItemType SymbolicLink -Path $configFileTarget -Target $configFileSource -Force | Out-Null
            Write-Host "🔗 Linked powershell.config.json"
        }
        catch {
            Copy-Item -Path $configFileSource -Destination $configFileTarget -Force
            Write-Host "📄 Copied powershell.config.json (symlink fallback)"
        }
    }
    else {
        Write-Host "✅ powershell.config.json already exists"
    }
}

# Install required modules if missing
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    winget install JanDeDobbeleer.OhMyPosh -s winget
}

if (-not (Get-Module Terminal-Icons -ListAvailable)) {
    Install-Module -Name Terminal-Icons -Force -Scope CurrentUser
}

if (-not (Get-Module PSReadLine -ListAvailable)) {
    Install-Module -Name PSReadLine -Force -Scope CurrentUser
}
