Param()
$ErrorActionPreference = 'Stop'

Write-Host '🔍 Testing PowerShell alias regeneration script (if present)...'
$repoRoot = Split-Path -Parent $PSScriptRoot
$profilePath = Join-Path $repoRoot 'PowerShell\Microsoft.PowerShell_profile.ps1'
if (-Not (Test-Path $profilePath)) {
  Write-Host 'SKIP: PowerShell profile not found'
  exit 0
}
try {
  . $profilePath
} catch {
  Write-Error ("FAIL: failed to load PowerShell profile: {0}" -f $_.Exception.Message)
  exit 1
}
# Simple heuristic: ensure at least one expected alias exists (e.g., 'projects')
if (Get-Command projects -ErrorAction SilentlyContinue) {
  Write-Host 'PASS: projects alias/function available'
  exit 0
} else {
  Write-Warning 'projects alias/function missing'
  exit 1
}
