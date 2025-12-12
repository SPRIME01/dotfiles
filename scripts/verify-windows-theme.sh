#!/usr/bin/env bash
set -euo pipefail

UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}\\home\\${USER}\\dotfiles"
ps_code=$(
	cat <<PWS
if (-not \$env:DOTFILES_ROOT -or [string]::IsNullOrWhiteSpace(\$env:DOTFILES_ROOT)) {
  \$env:DOTFILES_ROOT = "$UNC"
}
\$omp = if ([string]::IsNullOrWhiteSpace(\$env:OMP_THEME)) { 'powerlevel10k_modern.omp.json' } else { \$env:OMP_THEME }
\$theme = Join-Path \$env:DOTFILES_ROOT (Join-Path 'PowerShell\\Themes' \$omp)
\$exists = Test-Path \$theme
\$ompv = if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh version } else { 'not found' }
[PSCustomObject]@{
  OMP_THEME   = \$omp
  ThemePath   = \$theme
  ThemeExists = \$exists
  OhMyPosh    = \$ompv
} | Format-List | Out-String
PWS
)

enc=$(printf "%s" "$ps_code" | iconv -f utf-8 -t utf-16le | base64 -w0)
powershell.exe -NoProfile -NonInteractive -EncodedCommand "$enc" | tr -d '\r'
