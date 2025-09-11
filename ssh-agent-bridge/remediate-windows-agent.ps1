<#
.SYNOPSIS
  Remediate a failed Windows ssh-agent + manifest setup for the WSL SSH bridge.

.DESCRIPTION
  Enables and starts the OpenSSH Authentication Agent service (with elevation),
  ensures an existing ed25519 key is loaded (never creates a new one), locates
  npiperelay.exe (attempts installation via scoop/choco if available), and writes
  bridge-manifest.json for WSL consumption.

  Idempotent and safe to rerun. If not elevated it will self-elevate via UAC.

.PARAMETER Force
  Overwrite the manifest even if it already exists.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File remediate-windows-agent.ps1

  Runs remediation (prompts for elevation) and prints summary.

#>
param(
  [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Section($msg) { Write-Host "== $msg ==" -ForegroundColor Cyan }
function Write-Info($msg)    { Write-Host "[INFO] $msg" -ForegroundColor Gray }
function Write-Warn($msg)    { Write-Warning $msg }
function Write-Err($msg)     { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# --- Elevation check / self elevate ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Info "Not elevated; attempting to relaunch with elevation..."
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"$PSCommandPath")
  if ($Force) { $args += '-Force' }
  try {
    Start-Process -FilePath 'PowerShell' -Verb RunAs -ArgumentList $args | Out-Null
  } catch {
    Write-Err "Failed to relaunch elevated: $($_.Exception.Message)"
    exit 2
  }
  exit 0
}

Write-Section "Windows SSH Agent Remediation"
Write-Info "User=$env:USERNAME Host=$env:COMPUTERNAME Force=$Force"

# --- Enable & start service ---
Write-Section "Enable/Start ssh-agent service"
try {
  $svc = Get-Service ssh-agent -ErrorAction Stop
} catch {
  Write-Err "ssh-agent service not found. Install Windows OpenSSH Client (Optional Features)."
  exit 3
}

if ($svc.StartType -ne 'Automatic') {
  Write-Info "Setting StartType=Automatic"
  Set-Service -Name ssh-agent -StartupType Automatic
}

if ($svc.Status -ne 'Running') {
  Write-Info "Starting ssh-agent service"
  Start-Service ssh-agent
}

$svc = Get-Service ssh-agent
Write-Info "Service Status=$($svc.Status) StartType=$($svc.StartType)"
if ($svc.Status -ne 'Running') { Write-Err "Service failed to start"; exit 4 }

# --- Ensure key exists ---
Write-Section "Validate existing ed25519 key"
$key    = Join-Path $env:USERPROFILE '.ssh\id_ed25519'
$keyPub = "$key.pub"
if (-not (Test-Path $key)) { Write-Err "Expected key missing: $key (will not auto-create)"; exit 5 }
if (-not (Test-Path $keyPub)) { Write-Err "Missing public key: $keyPub"; exit 6 }

# --- Ensure key loaded ---
Write-Section "Load key into agent if absent"
$pubLine = (Get-Content $keyPub -TotalCount 1)
$comment = ($pubLine -split '\s+')[-1]
$already = $false
try {
  $list = ssh-add -l 2>$null
  if ($list -and $comment -and ($list | Select-String -SimpleMatch $comment)) { $already = $true }
} catch { }
if (-not $already) {
  Write-Info "Loading key into agent"
  ssh-add $key | Out-Null
} else {
  Write-Info "Key already loaded"
}
ssh-add -l | ForEach-Object { Write-Host "  $_" }

# --- Locate or install npiperelay.exe ---
Write-Section "Locate npiperelay.exe"
$np = (Get-Command npiperelay.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source)
if (-not $np) {
  Write-Warn "npiperelay.exe not found on PATH; attempting installation (scoop/choco)."
  if (Get-Command scoop -ErrorAction SilentlyContinue) {
    try { scoop install npiperelay | Out-Null } catch { Write-Warn "scoop install failed: $($_.Exception.Message)" }
  } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    try { choco install npiperelay -y | Out-Null } catch { Write-Warn "choco install failed: $($_.Exception.Message)" }
  } else {
    Write-Warn "Neither scoop nor choco available; install npiperelay manually."
  }
  $np = (Get-Command npiperelay.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -Expand Source)
}
if (-not $np) { Write-Warn "Proceeding without npiperelay path (manifest will still be written)." }
else { Write-Info "npiperelay.exe => $np" }

# --- Write manifest ---
Write-Section "Write manifest"
$manifestPath = Join-Path $env:USERPROFILE '.ssh\bridge-manifest.json'
if ((Test-Path $manifestPath) -and -not $Force) {
  Write-Info "Manifest already exists (use -Force to overwrite): $manifestPath"
} else {
  $npWsl = $null
  if ($np) {
    # Convert Windows path (C:\...) to WSL (/mnt/c/...) form for convenience
    if ($np -match '^[A-Za-z]:\\') {
      $drive = $np.Substring(0,1).ToLower()
      $rest  = $np.Substring(2) -replace '\\','/'
      $npWsl = "/mnt/$drive/$rest"
    }
  }
    $manifestObj = [ordered]@{
      npiperelay_path     = $np                # Original Windows path (backwards compatible)
      npiperelay_wsl      = $npWsl             # Direct WSL-usable path (expected by WSL installer)
      windows_user        = $env:USERNAME
      windows_host        = $env:COMPUTERNAME
      created_utc         = (Get-Date).ToUniversalTime().ToString('o')
      key_public_path_wsl = "/mnt/c/Users/$($env:USERNAME)/.ssh/id_ed25519.pub"
    }
  $json = $manifestObj | ConvertTo-Json -Depth 5
  $json | Out-File -FilePath $manifestPath -Encoding UTF8
  Write-Info "Wrote manifest: $manifestPath"
}

Write-Section "Summary"
Write-Host "Service: $($svc.Status) (StartType=$($svc.StartType))" -ForegroundColor Green
Write-Host "Key: $(Split-Path -Leaf $key) loaded=$((ssh-add -l 2>$null | Select-String -SimpleMatch $comment) -ne $null)" -ForegroundColor Green
Write-Host "Manifest: $manifestPath (Exists=$([bool](Test-Path $manifestPath)))" -ForegroundColor Green
if ($np) { Write-Host "npiperelay: $np" -ForegroundColor Green } else { Write-Warn "npiperelay still missing" }
Write-Host "Done." -ForegroundColor Green
