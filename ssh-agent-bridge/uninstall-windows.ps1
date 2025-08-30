\
[CmdletBinding()]
param([switch]$DisableAgent)
Write-Host "Removing manifest logs (keeping keys intact)..."
$ssh = Join-Path $env:USERPROFILE ".ssh"
$manifest = Join-Path $ssh "bridge-manifest.json"
if (Test-Path $manifest) { Remove-Item $manifest -Force }
Write-Host "Left your keys untouched at $ssh"
if ($DisableAgent) {
  Set-Service ssh-agent -StartupType Manual -ErrorAction SilentlyContinue
  Stop-Service ssh-agent -ErrorAction SilentlyContinue
  Write-Host "ssh-agent set to Manual and stopped."
}
