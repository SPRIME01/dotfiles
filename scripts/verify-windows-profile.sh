#!/usr/bin/env bash
set -euo pipefail

echo "=== Windows PowerShell (v5) ==="
ps_v5=$(
	cat <<'PWS'
$pi = Get-Item $PROFILE -ErrorAction SilentlyContinue
$root = $env:DOTFILES_ROOT
$main = if ($root) { Join-Path $root 'PowerShell\Microsoft.PowerShell_profile.ps1' } else { $null }
[PSCustomObject]@{
  Host              = 'WindowsPowerShell'
  Profile           = $PROFILE
  Exists            = Test-Path $PROFILE
  LinkType          = $pi.LinkType
  Target            = $pi.Target
  DOTFILES_ROOT     = $root
  MainProfile       = $main
  MainProfileExists = if ($main) { Test-Path $main } else { $false }
  OMP_THEME         = $env:OMP_THEME
} | Format-List | Out-String
PWS
)
enc_v5=$(printf "%s" "$ps_v5" | iconv -f utf-8 -t utf-16le | base64 -w0)
powershell.exe -NoProfile -NonInteractive -EncodedCommand "$enc_v5" | tr -d '\r'

echo
if command -v pwsh.exe >/dev/null 2>&1; then
	echo "=== PowerShell 7 (pwsh) ==="
	ps_v7=$(
		cat <<'PWS'
  $pi = Get-Item $PROFILE -ErrorAction SilentlyContinue
  $root = $env:DOTFILES_ROOT
  $main = if ($root) { Join-Path $root 'PowerShell\Microsoft.PowerShell_profile.ps1' } else { $null }
  [PSCustomObject]@{
    Host              = 'PowerShell7'
    Profile           = $PROFILE
    Exists            = Test-Path $PROFILE
    LinkType          = $pi.LinkType
    Target            = $pi.Target
    DOTFILES_ROOT     = $root
    MainProfile       = $main
    MainProfileExists = if ($main) { Test-Path $main } else { $false }
    OMP_THEME         = $env:OMP_THEME
  } | Format-List | Out-String
PWS
	)
	enc_v7=$(printf "%s" "$ps_v7" | iconv -f utf-8 -t utf-16le | base64 -w0)
	pwsh.exe -NoProfile -NonInteractive -EncodedCommand "$enc_v7" | tr -d '\r'
fi
