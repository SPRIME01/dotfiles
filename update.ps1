Write-Host "📡 Checking for updates from dotfiles..."

$dotfiles = "$HOME\dotfiles"
$branch = "main"

if (-not (Test-Path "$dotfiles\.git")) {
    Write-Host "❌ Dotfiles repo not found at $dotfiles"
    exit
}

Set-Location $dotfiles

# Detect uncommitted changes and stash them to avoid merge conflicts.  The
# changes will be reapplied after the update completes.
$stashed = $false
if ((git status --porcelain) -ne '') {
    Write-Host "🔄 Uncommitted changes detected; stashing before update..."
    $timestamp = Get-Date -Format yyyyMMddHHmmss
    git stash push -u -m "auto-stash-before-update-$timestamp" | Out-Null
    $stashed = $true
}

git pull origin $branch

Write-Host "✅ Repo synced. Reapplying configs..."

& "$dotfiles\bootstrap.ps1"

# Reapply any stashed changes after updating
if ($stashed) {
    Write-Host "🔁 Restoring your local changes from the stash..."
    git stash pop | Out-Null
}

Write-Host "🧼 Update complete: dotfiles refreshed from '$branch'"

