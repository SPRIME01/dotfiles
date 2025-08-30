[CmdletBinding()]
param()
$SshDir = Join-Path $env:USERPROFILE ".ssh"
$Manifest = Join-Path $SshDir "bridge-manifest.json"
Write-Host "Windows user: $env:USERNAME"
Write-Host "Checking ssh-agent service..."
Get-Service ssh-agent | Format-Table Status,StartType -Auto
Write-Host "`nAgent keys (ssh-add -l):"
ssh-add -l
Write-Host "`nManifest exists:" (Test-Path $Manifest)
if (Test-Path $Manifest) {
  Write-Host (Get-Content $Manifest -Raw)
}
