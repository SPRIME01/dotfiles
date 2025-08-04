# PowerShell common aliases
# Part of the modular dotfiles configuration system

# Navigation aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Git aliases
function gs { git status @args }
function ga { git add @args }
function gc { git commit @args }
function gp { git push @args }
function gl { git log --oneline @args }
function gd { git diff @args }
function gb { git branch @args }
function gco { git checkout @args }

# Directory aliases
function dotfiles { Set-Location $env:DOTFILES_ROOT }
function projects { Set-Location $env:PROJECTS_ROOT }
function home { Set-Location $env:USERPROFILE }

# Utility aliases
function h { Get-History }
function c { Clear-Host }
function e { exit }
function reload {
    # Reload PowerShell profile
    if (Test-Path $PROFILE) {
        . $PROFILE
        Write-Host "PowerShell profile reloaded" -ForegroundColor Green
    } else {
        Write-Warning "PowerShell profile not found at: $PROFILE"
    }
}

# Development aliases
function py { python @args }
function serve { python -m http.server @args }

# Docker aliases (if docker is available)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    function dk { docker @args }
    function dc { docker-compose @args }
    function dps { docker ps @args }
    function di { docker images @args }
}

# VS Code aliases (if code is available)
if (Get-Command code -ErrorAction SilentlyContinue) {
    function code. { code . }
}

# Platform-specific aliases will be loaded from platform-specific modules
