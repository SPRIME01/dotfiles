#
# PowerShell theme management functions
# dotfiles/PowerShell/Modules/Aliases/Set-OhMyPoshTheme.ps1
# Last Modified: July 20, 2025
#

<#
.SYNOPSIS
    Switch Oh My Posh themes dynamically
.DESCRIPTION
    Allows switching between available Oh My Posh themes in your dotfiles collection.
    The theme preference is saved for future sessions.
.PARAMETER ThemeName
    Name of the theme to switch to (without .omp.json extension)
.PARAMETER List
    List all available themes
.EXAMPLE
    Set-OhMyPoshTheme powerlevel10k-inspired
    Switch to the Powerlevel10k-inspired theme
.EXAMPLE
    Set-OhMyPoshTheme -List
    List all available themes
#>
function Set-OhMyPoshTheme {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$ThemeName,

        [switch]$List
    )

    $themesPath = "$HOME\dotfiles\PowerShell\Themes"

    if ($List) {
        Write-Host "📎 Available Oh My Posh themes:" -ForegroundColor Cyan
        Get-ChildItem -Path $themesPath -Filter "*.omp.json" | ForEach-Object {
            $name = $_.BaseName
            $indicator = if ($name -eq "powerlevel10k-inspired") { " (recommended)" } else { "" }
            Write-Host "  • $name$indicator" -ForegroundColor Yellow
        }
        return
    }

    if (-not $ThemeName) {
        Write-Host "Usage: Set-OhMyPoshTheme <theme-name>" -ForegroundColor Red
        Write-Host "Use 'Set-OhMyPoshTheme -List' to see available themes" -ForegroundColor Yellow
        return
    }

    $themeFile = "$themesPath\$ThemeName.omp.json"
    if (-not (Test-Path $themeFile)) {
        Write-Host "❌ Theme '$ThemeName' not found!" -ForegroundColor Red
        Write-Host "Available themes:" -ForegroundColor Yellow
        Set-OhMyPoshTheme -List
        return
    }

    # Set environment variable for current session
    $env:OMP_THEME = "$ThemeName.omp.json"

    # Save preference to user profile (Windows)
    $userEnvPath = "HKCU:\Environment"
    if (Test-Path $userEnvPath) {
        try {
            Set-ItemProperty -Path $userEnvPath -Name "OMP_THEME" -Value "$ThemeName.omp.json"
            Write-Host "✅ Theme preference saved for future sessions" -ForegroundColor Green
        }
        catch {
            Write-Warning "Could not save theme preference to registry"
        }
    }

    # Reinitialize Oh My Posh with new theme
    oh-my-posh init pwsh --config "$themeFile" | Invoke-Expression

    Write-Host "🎨 Switched to theme: $ThemeName" -ForegroundColor Green
    Write-Host "💡 Restart PowerShell to see the full effect" -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Get current Oh My Posh theme information
.DESCRIPTION
    Displays the currently active Oh My Posh theme and available alternatives
#>
function Get-OhMyPoshTheme {
    [CmdletBinding()]
    param()

    $currentTheme = if ($env:OMP_THEME) {
        $env:OMP_THEME.Replace('.omp.json', '')
    } else {
        "powerlevel10k-inspired (default)"
    }

    Write-Host "🎨 Current theme: $currentTheme" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available themes:" -ForegroundColor Yellow
    Set-OhMyPoshTheme -List
    Write-Host ""
    Write-Host "💡 Use 'Set-OhMyPoshTheme <theme-name>' to switch themes" -ForegroundColor Green
}
