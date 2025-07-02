Write-Host "📡 Checking for updates from dotfiles..."

$dotfiles = "$HOME\dotfiles"
$branch = "main"

if (-not (Test-Path "$dotfiles\.git")) {
    Write-Host "❌ Dotfiles repo not found at $dotfiles"
    exit
}

Set-Location $dotfiles
git pull origin $branch

Write-Host "✅ Repo synced. Reapplying configs..."

& "$dotfiles\bootstrap.ps1"

Write-Host "🧼 Update complete: dotfiles refreshed from '$branch'"

