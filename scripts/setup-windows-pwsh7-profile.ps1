# Setup Windows PowerShell 7 Profile
# This script creates the necessary profile and symlinks for PowerShell 7 on Windows
# Run this from Windows PowerShell (not PowerShell 7) with:
# powershell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\<WSL_DISTRO>\home\<WSL_USER>\dotfiles\scripts\setup-windows-pwsh7-profile.ps1"

param(
    [string]$WSLDistro = $null,
    [string]$WSLUser = $null,
    [switch]$Force,
    [switch]$DryRun,
    [switch]$RequireSymlink
)

Write-Host "🔧 Setting up Windows PowerShell 7 profile..." -ForegroundColor Cyan

try {
    # Detect environment variables
    $windowsUser = $env:USERNAME
    $detectedWSLDistro = $env:WSL_DISTRO_NAME

    # Use provided parameters or detect/assume values
    # Discover default WSL distro reliably
    if ($WSLDistro) {
        $wslDistro = $WSLDistro
    } else {
        try {
            $wslList = & wsl.exe -l -v 2>$null
            $wslDistro = ($wslList | Where-Object { $_ -match '\*' } | ForEach-Object { ($_ -split '\s+')[1] } | Select-Object -First 1)
            if (-not $wslDistro) { $wslDistro = 'Ubuntu-24.04' }
        } catch { $wslDistro = 'Ubuntu-24.04' }
    }

    # Discover WSL username by asking the distro directly (fallback to Windows username)
    if ($WSLUser) {
        $wslUser = $WSLUser
    } else {
        try {
            $wslUser = (& wsl.exe -d $wslDistro -e sh -lc 'echo -n $USER' 2>$null)
            if (-not $wslUser -or $wslUser.Trim() -eq '') { $wslUser = $windowsUser.ToLower() }
        } catch { $wslUser = $windowsUser.ToLower() }
    }

    Write-Host "🔍 Environment detection:" -ForegroundColor Cyan
    Write-Host "  Windows user: $windowsUser" -ForegroundColor White
    Write-Host "  WSL distro: $wslDistro $(if ($detectedWSLDistro) { '(detected)' } else { '(assumed)' })" -ForegroundColor White
    Write-Host "  WSL user: $wslUser $(if ($env:USER) { '(detected)' } else { '(assumed)' })" -ForegroundColor White

    # Get the Windows PowerShell 7 profile path without loading profiles or emitting warnings
    # Notes:
    # -NoProfile avoids executing the user's profile (which can print warnings)
    # -NoLogo/-NonInteractive reduce noise; redirect stderr to $null to drop any stray messages
    $pwsh7ProfilePathRaw = & pwsh -NoProfile -NoLogo -NonInteractive -Command '$PROFILE' 2>$null
    # In case anything still writes extra lines, take the last non-empty line and trim
    $pwsh7ProfilePath = ($pwsh7ProfilePathRaw | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Last 1).Trim()
    Write-Host "PowerShell 7 profile path: $pwsh7ProfilePath" -ForegroundColor Yellow

    # Get the profile directory
    $profileDir = Split-Path -Parent $pwsh7ProfilePath

    if ($DryRun) {
        Write-Host "📝 (dry-run) Would ensure profile directory exists: $profileDir" -ForegroundColor DarkGray
    } else {
    # Create the profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        Write-Host "✅ Created profile directory: $profileDir" -ForegroundColor Green
    }
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

    # If running in a non-interactive test context, allow early exit after ensuring paths
    if ($env:DOTFILES_PWSH_NONINTERACTIVE -in @('1','true','True','TRUE','yes','YES')) {
        Write-Host "(non-interactive) Skipping interactive profile loading" -ForegroundColor DarkGray
    }

    # Prefer creating a Windows symlink at $PROFILE that points to the repo profile in WSL
    # Check Developer Mode status to inform user
    $devKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    $devMode = (Get-ItemProperty -Path $devKey -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    if (-not $devMode -or $devMode -eq 0) {
        Write-Warning "Windows Developer Mode appears OFF; symlink may require elevation."
        Write-Host "Enable Settings → For Developers → Developer Mode for best results." -ForegroundColor Yellow
    }
    $targetProfile = Join-Path $dotfilesPath 'PowerShell\Microsoft.PowerShell_profile.ps1'
    $createdSymlink = $false
    if ($DryRun) {
        Write-Host "📝 (dry-run) Would create symbolic link:" -ForegroundColor DarkGray
        Write-Host "     Path:   $pwsh7ProfilePath" -ForegroundColor DarkGray
        Write-Host "     Target: $targetProfile" -ForegroundColor DarkGray
        Write-Host "📝 (dry-run) If symlink creation fails, would write loader profile instead" -ForegroundColor DarkGray
    } else {
        try {
            if (Test-Path $pwsh7ProfilePath) {
                $existing = Get-Item $pwsh7ProfilePath -ErrorAction SilentlyContinue
                if ($existing -and -not $existing.LinkType) {
                    # Remove regular file to allow symlink creation
                    Remove-Item -Path $pwsh7ProfilePath -Force -ErrorAction SilentlyContinue
                }
            }
            New-Item -ItemType SymbolicLink -Path $pwsh7ProfilePath -Target $targetProfile -Force | Out-Null
            Write-Host "✅ Created symbolic link: $pwsh7ProfilePath -> $targetProfile" -ForegroundColor Green
            $createdSymlink = $true
        } catch {
            Write-Warning "Could not create symbolic link (developer mode or elevation may be required): $($_.Exception.Message)"
            $createdSymlink = $false
        }
    }

    if (-not $createdSymlink) {
        if ($RequireSymlink) {
            throw "Required symlink could not be created; aborting as requested."
        }
        # Fallback: write a tiny loader profile that points to the repo
        $profileContent = @"
# Windows PowerShell 7 Profile - Auto-generated $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# This profile loads the main PowerShell profile from the dotfiles repository
# Generated for: Windows user '$windowsUser', WSL user '$wslUser', WSL distro '$wslDistro'

# Set DOTFILES_ROOT for Windows
`$env:DOTFILES_ROOT = "$dotfilesPath"

# Set PROJECTS_ROOT for Windows (path only; avoid creating it here)
if (-not `$env:PROJECTS_ROOT) {
    `$env:PROJECTS_ROOT = Join-Path `$env:USERPROFILE 'projects'
}

    # Source the main profile
`$mainProfile = Join-Path `$env:DOTFILES_ROOT 'PowerShell\Microsoft.PowerShell_profile.ps1'

# Gently wake WSL and wait for UNC availability (race-proof)
try { wsl.exe -l -q *> `$null } catch { }

`$maxAttempts = 12
`$delayMs = 250
for (`$i = 0; `$i -lt `$maxAttempts -and -not (Test-Path `$mainProfile); `$i++) {
    if (`$i -eq 0) { Write-Host "⏳ Waiting for WSL path..." -ForegroundColor DarkGray }
    Start-Sleep -Milliseconds `$delayMs
}

if (-not (Test-Path `$mainProfile)) {
    Write-Warning "WSL UNC not available after `$([int](`$maxAttempts*`$delayMs/1000))s; continuing with fallback if needed."
}

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

        if ($DryRun) {
            Write-Host "📝 (dry-run) Would write loader profile to: $pwsh7ProfilePath" -ForegroundColor DarkGray
        } else {
            # Write the loader profile
            try {
                Set-Content -Path $pwsh7ProfilePath -Value $profileContent -Encoding utf8
                Write-Host "✅ Created PowerShell 7 loader profile at: $pwsh7ProfilePath" -ForegroundColor Green
            } catch {
                # Fallback for older PowerShell versions that don't support -Encoding utf8
                Set-Content -Path $pwsh7ProfilePath -Value $profileContent
                Write-Host "✅ Created PowerShell 7 loader profile at: $pwsh7ProfilePath" -ForegroundColor Green
            }
        }
    }

    # Clean up old/duplicate profile locations (backup and remove)
    Write-Host "🧹 Cleaning up old profile locations..." -ForegroundColor Cyan
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $candidates = @()
    $candidates += Join-Path (Join-Path $env:USERPROFILE 'Documents\PowerShell') 'Microsoft.PowerShell_profile.ps1'
    # OneDrive paths intentionally omitted to avoid coupling to OneDrive
    # Legacy WindowsPowerShell profiles (not used by pwsh, but can confuse)
    $candidates += Join-Path (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell') 'Microsoft.PowerShell_profile.ps1'
    # OneDrive paths intentionally omitted to avoid coupling to OneDrive

    foreach ($path in $candidates | Select-Object -Unique) {
        try {
            if ((Test-Path $path) -and ($path -ne $pwsh7ProfilePath)) {
                $backup = "$path.backup.$timestamp"
                Move-Item -Path $path -Destination $backup -Force
                Write-Host "  ✅ Backed up: $path → $backup" -ForegroundColor Green
            }
        } catch {
            Write-Warning "  ⚠️  Could not process ${path}: $($_.Exception.Message)"
        }
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
