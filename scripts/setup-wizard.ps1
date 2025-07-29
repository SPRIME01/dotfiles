<#
    Interactive setup wizard for Windows PowerShell users.  This script guides
    you through configuring your PowerShell environment, installing optional
    components and enabling advanced features.  It wraps `bootstrap.ps1`
    and copies the post‑commit git hook if requested.

    Run this script from the root of your dotfiles repository:

        pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup-wizard.ps1
#>

Param()

function Prompt-YesNo {
    param(
        [string]$Message,
        [string]$Default = 'Y'
    )
    $prompt = if ($Default -eq 'Y') { "$Message [Y/n] " } else { "$Message [y/N] " }
    $response = Read-Host $prompt
    if (-not $response) { $response = $Default }
    return $response -match '^[Yy]$'
}

Write-Host "📦 Welcome to the dotfiles setup wizard!" -ForegroundColor Cyan

$configurePwsh = Prompt-YesNo -Message 'Do you want to configure PowerShell?' -Default 'Y'
$installVsCode = Prompt-YesNo -Message 'Install VS Code settings? (Linux/WSL only)' -Default 'N'
$enableHook    = Prompt-YesNo -Message 'Install post-commit hook to auto-regenerate PowerShell aliases?' -Default 'Y'

Write-Host ""  # blank line
Write-Host "🔧 Applying your selections..." -ForegroundColor Cyan

if ($configurePwsh) {
    Write-Host "▶️  Running PowerShell bootstrap script..."
    & "$PSScriptRoot\..\bootstrap.ps1"
}

if ($installVsCode) {
    Write-Warning "VS Code settings installation is only supported on Unix-like systems.  Please run install/vscode.sh from WSL or Linux."
}

if ($enableHook) {
    $hookSrc = Join-Path $PSScriptRoot '..\scripts\git-hooks\post-commit'
    $hookDest = Join-Path (Join-Path $PSScriptRoot '..\.git\hooks') 'post-commit'
    if (Test-Path $hookSrc) {
        Write-Host "▶️  Installing post-commit hook at .git/hooks/post-commit"
        New-Item -ItemType Directory -Path (Split-Path $hookDest) -Force | Out-Null
        Copy-Item -Path $hookSrc -Destination $hookDest -Force
        # Ensure the hook is executable for git (permissions on Windows are
        # generally permissive, but we set the hidden attribute off)
        (Get-Item $hookDest).Attributes = 'Normal'
    } else {
        Write-Warning "Hook script not found at $hookSrc; skipping."
    }
}

Write-Host ""  # blank line
Write-Host "🎉 Setup complete!  Please restart your PowerShell sessions to load the new configuration." -ForegroundColor Green