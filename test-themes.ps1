#!/usr/bin/env pwsh
# dotfiles/test-themes.ps1
# Quick verification that theme system is working
# Version: 1.0

Write-Host "🧪 Testing theme system..." -ForegroundColor Cyan

# Test theme files exist
$themesPath = "$HOME\dotfiles\PowerShell\Themes"
$requiredThemes = @(
    "powerlevel10k_classic.omp.json",
    "powerlevel10k_modern.omp.json",
    "powerlevel10k_lean.omp.json",
    "minimal-clean.omp.json",
    "emodipt-extend.omp.json"
)

Write-Host "📁 Checking theme files..." -ForegroundColor Yellow
foreach ($theme in $requiredThemes) {
    $themePath = Join-Path $themesPath $theme
    if (Test-Path $themePath) {
        Write-Host "  ✅ $theme" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $theme (missing)" -ForegroundColor Red
    }
}

# Test Oh My Posh is available
Write-Host "🔧 Checking Oh My Posh..." -ForegroundColor Yellow
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $version = oh-my-posh version
    Write-Host "  ✅ Oh My Posh $version" -ForegroundColor Green
}
else {
    Write-Host "  ❌ Oh My Posh not found" -ForegroundColor Red
}

# Test theme functions
Write-Host "⚙️  Checking theme functions..." -ForegroundColor Yellow
$functions = @("Set-OhMyPoshTheme", "Get-OhMyPoshTheme")
foreach ($func in $functions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ $func" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $func (not loaded)" -ForegroundColor Red
    }
}

# Show current configuration
Write-Host "🎨 Current theme configuration:" -ForegroundColor Cyan
$currentTheme = if ($env:OMP_THEME) { $env:OMP_THEME } else { "powerlevel10k_classic.omp.json (default)" }
Write-Host "  Theme: $currentTheme" -ForegroundColor White

Write-Host ""
Write-Host "🎯 Test complete!" -ForegroundColor Green
Write-Host "💡 Try: settheme powerlevel10k_classic" -ForegroundColor Yellow
