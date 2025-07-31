# Setup Windows PowerShell 7 Profile
# This script creates the necessary profile and symlinks for PowerShell 7 on Windows
# Run this from Windows PowerShell (not PowerShell 7) with:
# powershell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\<WSL_DISTRO>\home\<WSL_USER>\dotfiles\scripts\setup-windows-pwsh7-profile.ps1"

param(
    [string]$WSLDistro = $null,
    [string]$WSLUser = $null,
    [switch]$Force
)

Write-Host "🔧 Setting up Windows PowerShell 7 profile..." -ForegroundColor Cyan

try {
    # Detect environment variables
    $windowsUser = $env:USERNAME
    $detectedWSLDistro = $env:WSL_DISTRO_NAME

    # Use provided parameters or detect/assume values
    $wslDistro = if ($WSLDistro) {
        $WSLDistro
    } elseif ($detectedWSLDistro) {
        $detectedWSLDistro
    } else {
        "Ubuntu-24.04"  # Common default
    }

    $wslUser = if ($WSLUser) {
        $WSLUser
    } elseif ($env:USER) {
        $env:USER
    } else {
        $windowsUser.ToLower()  # Assume WSL user matches Windows user (common case)
    }

    Write-Host "🔍 Environment detection:" -ForegroundColor Cyan
    Write-Host "  Windows user: $windowsUser" -ForegroundColor White
    Write-Host "  WSL distro: $wslDistro $(if ($detectedWSLDistro) { '(detected)' } else { '(assumed)' })" -ForegroundColor White
    Write-Host "  WSL user: $wslUser $(if ($env:USER) { '(detected)' } else { '(assumed)' })" -ForegroundColor White

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

    # Determine the best path to dotfiles - prefer WSL path for consistency
    $windowsDotfilesPath = Join-Path $env:USERPROFILE "dotfiles"
    $wslDotfilesPath = "\\wsl.localhost\$wslDistro\home\$wslUser\dotfiles"

    # Test which path works and prefer WSL
    $dotfilesPath = if (Test-Path $wslDotfilesPath) {
        Write-Host "✅ Using WSL dotfiles path: $wslDotfilesPath" -ForegroundColor Green
        $wslDotfilesPath
    } elseif (Test-Path $windowsDotfilesPath) {
        Write-Host "⚠️  Using Windows dotfiles path: $windowsDotfilesPath" -ForegroundColor Yellow
        Write-Host "💡 Consider using WSL path for better integration" -ForegroundColor Yellow
        $windowsDotfilesPath
    } else {
        Write-Warning "Neither WSL nor Windows dotfiles path found!"
        Write-Host "💡 WSL path: $wslDotfilesPath" -ForegroundColor Yellow
        Write-Host "💡 Windows path: $windowsDotfilesPath" -ForegroundColor Yellow
        Write-Host "💡 Using WSL path anyway (ensure WSL is running)" -ForegroundColor Yellow
        $wslDotfilesPath
    }

    # Create the profile content that sources the main profile
    $profileContent = @"
# Windows PowerShell 7 Profile - Auto-generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# This profile sources the main PowerShell profile from the dotfiles repository
# Generated for: Windows user '$windowsUser', WSL user '$wslUser', WSL distro '$wslDistro'

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

# Debug information (comment out in production)
Write-Host "🔍 Debug: DOTFILES_ROOT = `$env:DOTFILES_ROOT" -ForegroundColor DarkGray
Write-Host "🔍 Debug: PROJECTS_ROOT = `$env:PROJECTS_ROOT" -ForegroundColor DarkGray

# Source the main profile
`$mainProfile = Join-Path `$env:DOTFILES_ROOT 'PowerShell\Microsoft.PowerShell_profile.ps1'
Write-Host "🔍 Debug: Looking for main profile at: `$mainProfile" -ForegroundColor DarkGray

if (Test-Path `$mainProfile) {
    try {
        . `$mainProfile
        Write-Host "✅ Loaded dotfiles PowerShell profile" -ForegroundColor Green
    } catch {
        Write-Warning "Error loading main profile: `$(`$_.Exception.Message)"
        Write-Host "💡 Check if WSL is running and dotfiles are accessible" -ForegroundColor Yellow

        # Create basic functions as fallback
        function global:projects { Set-Location -Path `$env:PROJECTS_ROOT }
        Write-Host "📦 Created basic 'projects' function as fallback" -ForegroundColor Blue
    }
} else {
    Write-Warning "Main PowerShell profile not found at: `$mainProfile"
    Write-Host "💡 Make sure WSL is running and dotfiles repository is accessible" -ForegroundColor Yellow
    Write-Host "💡 Expected WSL path: \\wsl.localhost\\$wslDistro\\home\\$wslUser\\dotfiles" -ForegroundColor Yellow

    # Create basic functions as fallback
    function global:projects { Set-Location -Path `$env:PROJECTS_ROOT }
    Write-Host "📦 Created basic 'projects' function as fallback" -ForegroundColor Blue
}
"@

    # Write the profile
    try {
        Set-Content -Path $pwsh7ProfilePath -Value $profileContent -Encoding utf8
        Write-Host "✅ Created PowerShell 7 profile at: $pwsh7ProfilePath" -ForegroundColor Green
    } catch {
        # Fallback for older PowerShell versions that don't support -Encoding utf8
        Set-Content -Path $pwsh7ProfilePath -Value $profileContent
        Write-Host "✅ Created PowerShell 7 profile at: $pwsh7ProfilePath" -ForegroundColor Green
    }

    Write-Host "`n✨ Setup complete!" -ForegroundColor Green
    Write-Host "Now you can:" -ForegroundColor Cyan
    Write-Host "  1. Open a new PowerShell 7 window (pwsh)" -ForegroundColor White
    Write-Host "  2. Run 'projects' to navigate to your projects directory" -ForegroundColor White
    Write-Host "  3. Use all your dotfiles aliases and functions" -ForegroundColor White

} catch {
    Write-Error "Failed to set up PowerShell 7 profile: $($_.Exception.Message)"
    Write-Host "💡 Make sure you're running this from Windows PowerShell with proper permissions" -ForegroundColor Yellow
}
