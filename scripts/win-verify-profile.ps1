Param()

$ErrorActionPreference = 'Stop'

$pi = Get-Item $PROFILE -ErrorAction SilentlyContinue
$root = $env:DOTFILES_ROOT
$main = if ($root) { Join-Path $root 'PowerShell\Microsoft.PowerShell_profile.ps1' } else { $null }

[PSCustomObject]@{
  Profile           = $PROFILE
  Exists            = Test-Path $PROFILE
  LinkType          = $pi.LinkType
  Target            = $pi.Target
  DOTFILES_ROOT     = $root
  MainProfile       = $main
  MainProfileExists = if ($main) { Test-Path $main } else { $false }
  OMP_THEME         = $env:OMP_THEME
} | Format-List | Out-String | Write-Host

