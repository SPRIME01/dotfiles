Param()

$ErrorActionPreference = 'Stop'

# Default/fallback root if not set
if (-not $env:DOTFILES_ROOT -or [string]::IsNullOrWhiteSpace($env:DOTFILES_ROOT)) {
  # Fallback to your known UNC path
  $env:DOTFILES_ROOT = "\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles"
}

$omp = if ([string]::IsNullOrWhiteSpace($env:OMP_THEME)) { 'powerlevel10k_modern.omp.json' } else { $env:OMP_THEME }
$theme = Join-Path $env:DOTFILES_ROOT (Join-Path 'PowerShell\Themes' $omp)
$exists = Test-Path $theme
$ompv = if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh version } else { 'not found' }

[PSCustomObject]@{
  OMP_THEME   = $omp
  ThemePath   = $theme
  ThemeExists = $exists
  OhMyPosh    = $ompv
} | Format-List | Out-String | Write-Host

