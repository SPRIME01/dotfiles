<# =====================================================================
install-win-ssh-agent.ps1
Idempotent Windows setup for OpenSSH agent + npiperelay discovery.
- Ensures OpenSSH.Client is installed (best-effort)
- Enables & starts ssh-agent
- Ensures an ed25519 key exists and is loaded
- Finds npiperelay.exe (Path/Scoop/Choco/common spots)
- Writes a manifest for WSL at %USERPROFILE%\.ssh\bridge-manifest.json
- Dry-run + verbose logging

Usage:
  .\install-win-ssh-agent.ps1 [-DryRun] [-Quiet] [-Verbose]
===================================================================== #>

[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Quiet
)

# Warn if running from a UNC path (e.g., \\wsl.localhost\...)
if ($PSCommandPath -like '\\\\*') {
    Write-Warning "You are running this script from a UNC path ($PSCommandPath)."
    Write-Warning "For reliability, copy the ssh-agent-bridge folder to a local path (e.g., C:\\Users\\$env:USERNAME\\Downloads) and rerun."
}

$ScriptName = Split-Path -Leaf $PSCommandPath
$SshDir     = Join-Path $env:USERPROFILE ".ssh"

# Primary log dir
$LogDir     = Join-Path $SshDir "logs"
$LogFile    = Join-Path $LogDir ("win-ssh-agent-setup_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$Manifest   = Join-Path $SshDir "bridge-manifest.json"

# Try to create log folder
try {
    New-Item -ItemType Directory -Force -Path $LogDir -ErrorAction Stop | Out-Null
} catch {
    # Fallback to TEMP if we can’t use ~/.ssh/logs
    $LogDir  = $env:TEMP
    $LogFile = Join-Path $LogDir ("win-ssh-agent-setup_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
    if (-not $Quiet) { Write-Warning "Could not create/access $($env:USERPROFILE)\.ssh\logs. Falling back to $LogDir" }
}

# Start transcript safely
try {
    Start-Transcript -Path $LogFile -Append | Out-Null
} catch {
    if (-not $Quiet) { Write-Warning "Transcript logging disabled: $($_.Exception.Message)" }
}

function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $ts = (Get-Date).ToString("s")
  $line = "[{0}] [{1}] {2}" -f $ts, $Level, $Message
  if (-not $Quiet) { Write-Host $line }
  try { Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue } catch {}
}


function Invoke-Step {
  param([scriptblock]$Action, [string]$What)
  Write-Log "STEP: $What"
  if ($DryRun) { Write-Log "DRY-RUN: $What" "WARN"; return }
  & $Action
  if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) {
    Write-Log "Non-zero exit code $LASTEXITCODE on: $What" "ERROR"
    throw "Step failed: $What"
  }
}

Write-Log "===== BEGIN Windows SSH-Agent Install ====="
Write-Log "Script=$ScriptName  DryRun=$DryRun  User=$($env:USERNAME)  Host=$(hostname)"

# Best-effort OpenSSH.Client
try {
  $cap = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Client*' }
  if ($cap -and $cap.State -ne 'Installed') {
    Invoke-Step { Add-WindowsCapability -Online -Name $cap.Name } "Install OpenSSH.Client"
  } else { Write-Log "OpenSSH.Client already installed" }
} catch { Write-Log "Capability check skipped: $($_.Exception.Message)" "WARN" }

# ssh-agent
$svc = Get-Service -Name ssh-agent -ErrorAction SilentlyContinue
if ($svc) {
  if ($svc.StartType -ne 'Automatic') {
    Invoke-Step { Set-Service -Name ssh-agent -StartupType Automatic } "Enable ssh-agent autostart"
  } else { Write-Log "ssh-agent autostart OK" }
  if ($svc.Status -ne 'Running') {
    Invoke-Step { Start-Service ssh-agent } "Start ssh-agent"
  } else { Write-Log "ssh-agent already running" }
} else {
  Write-Log "ssh-agent service not present on this OS SKU" "WARN"
}

# ed25519 key presence
Invoke-Step { New-Item -ItemType Directory -Path $SshDir -Force | Out-Null } "Ensure $SshDir exists"
$KeyPath = Join-Path $SshDir "id_ed25519"
if (-not (Test-Path $KeyPath)) {
  Invoke-Step { ssh-keygen -t ed25519 -C "$($env:USERNAME)@$(hostname)" -f $KeyPath -N "" } "Generate ed25519 key"
} else { Write-Log "ed25519 key present: $KeyPath" }
Invoke-Step { ssh-add $KeyPath | Out-Null } "ssh-add id_ed25519"
Invoke-Step { ssh-add -l } "List agent keys"

# Find npiperelay
function Find-NPipeRelay {
  $cmd = Get-Command npiperelay.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $candidates = @(
    "$env:USERPROFILE\scoop\apps\npiperelay\current\npiperelay.exe",
    "C:\ProgramData\chocolatey\bin\npiperelay.exe",
    "C:\Windows\System32\npiperelay.exe"
  )
  foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
  return $null
}
$NPipePath = Find-NPipeRelay
if (-not $NPipePath) {
  Write-Log "npiperelay.exe not found. Install with Scoop or Chocolatey." "ERROR"
  if (-not $DryRun) { throw "npiperelay.exe missing" }
} else {
  Write-Log "npiperelay: $NPipePath"
}

# Write/refresh manifest
function To-WslPath([string]$WinPath) {
  if (-not $WinPath) { return "" }
  $drive = $WinPath.Substring(0,1).ToLower()
  $tail  = $WinPath.Substring(2) -replace '\\','/'
  return "/mnt/$drive/$tail"
}
$ManifestObj = [ordered]@{
  version        = 1
  windows_user   = $env:USERNAME
  host           = $env:COMPUTERNAME
  npiperelay_win = $NPipePath
  npiperelay_wsl = if ($NPipePath) { To-WslPath $NPipePath } else { "" }
  ssh_key_path   = $KeyPath
  updated_at     = (Get-Date).ToString("s")
}
$ManifestJson = ($ManifestObj | ConvertTo-Json -Depth 3)
Write-Log "Writing manifest: $Manifest"
if (-not $DryRun) { Set-Content -Path $Manifest -Value $ManifestJson -Encoding UTF8 }

Write-Log "===== COMPLETE Windows SSH-Agent Install ====="
Write-Log "Log: $LogFile"
Stop-Transcript | Out-Null
