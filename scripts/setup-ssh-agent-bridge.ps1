<#
  Hardened helper for WSL SSH agent bridge on Windows side.
  - Ensures Windows OpenSSH Authentication Agent is running
  - Locates npiperelay.exe (if available) and prints its path
  - Does not assume any current directory
#>

$ErrorActionPreference = 'Stop'

Write-Host "Ensuring 'OpenSSH Authentication Agent' service is running..."
try {
  $svc = Get-Service -Name 'ssh-agent' -ErrorAction Stop
  if ($svc.Status -ne 'Running') {
    Start-Service -Name 'ssh-agent'
    $svc.WaitForStatus('Running','00:00:05') | Out-Null
  }
  Write-Host "ssh-agent service status:" $svc.Status
}
catch {
  Write-Warning "OpenSSH Authentication Agent is not installed. Install optional feature 'OpenSSH Client' and 'OpenSSH Server' or via Settings > Optional Features."
}

function Find-NpiperelayPath {
  $candidates = @()
  # If npiperelay is on PATH
  $cmd = Get-Command npiperelay.exe -ErrorAction SilentlyContinue
  if ($cmd) { $candidates += $cmd.Path }
  # Common install locations
  $candidates += @(
    "$Env:ProgramData\chocolatey\bin\npiperelay.exe",
    "$Env:ProgramFiles\npiperelay\npiperelay.exe",
    "$Env:USERPROFILE\bin\npiperelay.exe",
    "C:\\tools\\npiperelay\\npiperelay.exe"
  )
  foreach ($p in $candidates | Get-Unique) {
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  }
  return $null
}

$npiperelay = Find-NpiperelayPath
if ($npiperelay) {
  Write-Host "Found npiperelay.exe at:" $npiperelay
  Write-Host "In WSL, set NPIPERELAY_PATH to this path (e.g.):"
  Write-Host "  export NPIPERELAY_PATH=\"$(wslpath -a '$npiperelay')\""
} else {
  Write-Warning "Could not find npiperelay.exe. Install it (e.g., via Chocolatey: 'choco install npiperelay') and set NPIPERELAY_PATH in WSL."
}

Write-Host "Done."

