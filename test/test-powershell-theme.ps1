Param()
$ErrorActionPreference = 'Stop'
Write-Host '🔍 Testing PowerShell theme fallback...'
$repoRoot = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $repoRoot 'PowerShell\Microsoft.PowerShell_profile.ps1'
if (-Not (Test-Path $profilePath)) { Write-Host 'SKIP: profile missing'; exit 0 }
. $profilePath
# Force a non-existent theme to trigger fallback logic
$env:OMP_THEME = 'nonexistent-theme.omp.json'
try {
  . $profilePath
} catch {
  Write-Host 'FAIL: profile reload failed'
  Write-Error $_
  exit 1
}
Write-Host 'PASS: theme fallback executed without error'
exit 0
