# Setup Windows PowerShell 7 Profile
# This script creates the necessary profile and symlinks for PowerShell 7 on Windows
# Run this from Windows PowerShell (not PowerShell 7) with:
# powershell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\prime\dotfiles\scripts\setup-windows-pwsh7-profile.ps1"

Write-Host "🔧 Setting up Windows PowerShell 7 profile..." -ForegroundColor Cyan

try {
    # Get the Windows PowerShell 7 profile path
    $pwsh7ProfilePath = & pwsh -c '$PROFILE'
    Write-Host "PowerShell 7 profile path: $pwsh7ProfilePath" -ForegroundColor Yellow

    # Get the profile directory
    $profileDir = Split-Path -Parent $pwsh7ProfilePath

    # Create the profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "✅ Created profile directory: $profileDir" -ForegroundColor Green
    }

    # Determine the best path to dotfiles
    $windowsDotfilesPath = Join-Path $env:USERPROFILE "dotfiles"
    $wslDotfilesPath = "\\wsl.localhost\Ubuntu\home\$env:USERNAME\dotfiles"

    # Check if we have a Windows dotfiles directory or need to use WSL path
    $dotfilesPath = if (Test-Path $windowsDotfilesPath) {
        Write-Host "Using Windows dotfiles path: $windowsDotfilesPath" -ForegroundColor Green
        $windowsDotfilesPath
    } else {
        Write-Host "Using WSL dotfiles path: $wslDotfilesPath" -ForegroundColor Green
        $wslDotfilesPath
    }

    # Create the profile content that sources the main profile
    $profileContent = @"
# Windows PowerShell 7 Profile - Auto-generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# This profile sources the main PowerShell profile from the dotfiles repository

# Set DOTFILES_ROOT for Windows
`$env:DOTFILES_ROOT = "$dotfilesPath"

# Set PROJECTS_ROOT for Windows (ensure Projects directory exists)
if (-not `$env:PROJECTS_ROOT) {
    `$env:PROJECTS_ROOT = Join-Path `$env:USERPROFILE 'projects'
}

# Ensure projects directory exists
if (-not (Test-Path `$env:PROJECTS_ROOT)) {
    New-Item -ItemType Directory -Path `$env:PROJECTS_ROOT -Force | Out-Null
}

# Source the main profile
`$mainProfile = Join-Path `$env:DOTFILES_ROOT 'PowerShell\Microsoft.PowerShell_profile.ps1'
if (Test-Path `$mainProfile) {
    try {
        . `$mainProfile
        Write-Host "✅ Loaded dotfiles PowerShell profile" -ForegroundColor Green
    } catch {
        Write-Warning "Error loading main profile: `$(`$_.Exception.Message)"
    }
} else {
    Write-Warning "Main PowerShell profile not found at: `$mainProfile"
    Write-Host "💡 Make sure your dotfiles repository is accessible from Windows" -ForegroundColor Yellow

    # Create basic functions as fallback
    function global:projects { Set-Location -Path `$env:PROJECTS_ROOT }
    Write-Host "📦 Created basic 'projects' function as fallback" -ForegroundColor Blue
}
"@

    # Write the profile
    Set-Content -Path $pwsh7ProfilePath -Value $profileContent -Encoding UTF8
    Write-Host "✅ Created PowerShell 7 profile at: $pwsh7ProfilePath" -ForegroundColor Green

    Write-Host "`n✨ Setup complete!" -ForegroundColor Green
    Write-Host "Now you can:" -ForegroundColor Cyan
    Write-Host "  1. Open a new PowerShell 7 window (pwsh)" -ForegroundColor White
    Write-Host "  2. Run 'projects' to navigate to your projects directory" -ForegroundColor White
    Write-Host "  3. Use all your dotfiles aliases and functions" -ForegroundColor White

} catch {
    Write-Error "Failed to set up PowerShell 7 profile: $($_.Exception.Message)"
    Write-Host "💡 Make sure you're running this from Windows PowerShell with proper permissions" -ForegroundColor Yellow
}
