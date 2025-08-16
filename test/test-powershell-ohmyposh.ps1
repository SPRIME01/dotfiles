Param()
$ErrorActionPreference = 'Stop'
Write-Host '🔍 Testing PowerShell oh-my-posh availability...'
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) { Write-Host 'SKIP: oh-my-posh not installed in PATH'; exit 0 }
$version = (oh-my-posh version) 2>$null
if (-not $version) { Write-Host 'FAIL: could not get version'; exit 1 }
Write-Host "PASS: oh-my-posh present ($version)"
exit 0
