<# =====================================================================
rotate-ed25519.ps1
Safe, logged ed25519 rotation for Windows ssh-agent + WSL bridge.
- Backs up existing id_* into timestamped folder
- Generates new ed25519 (no passphrase by default; add one if desired)
- Loads it into the Windows ssh-agent
- Prints the Windows + WSL path of the public key
- Self-healing logging: falls back to %TEMP% if ~/.ssh/logs is blocked
- DryRun mode supported
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

# ----------------- Self-healing logging -----------------
$SshDir  = Join-Path $env:USERPROFILE ".ssh"
$LogDir  = Join-Path $SshDir "logs"
$LogFile = Join-Path $LogDir ("rotate-ed25519_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

try {
  New-Item -ItemType Directory -Force -Path $LogDir -ErrorAction Stop | Out-Null
} catch {
  $LogDir  = $env:TEMP
  $LogFile = Join-Path $LogDir ("rotate-ed25519_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
  if (-not $Quiet) { Write-Warning "Could not create/access $($env:USERPROFILE)\.ssh\logs. Falling back to $LogDir" }
}

try {
  Start-Transcript -Path $LogFile -Append | Out-Null
} catch {
  if (-not $Quiet) { Write-Warning "Transcript disabled: $($_.Exception.Message)" }
}

function Log { param([string]$m,[string]$lvl="INFO")
  $ts=(Get-Date).ToString("s")
  $line="[$ts][$lvl] $m"
  if(-not $Quiet){Write-Host $line}
  try { Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue } catch {}
}
function Step { param([scriptblock]$a,[string]$w)
  Log "STEP: $w"
  if($DryRun){ Log "DRY-RUN: $w" "WARN"; return }
  & $a
  if ($LASTEXITCODE -ne $null -and $LASTEXITCODE -ne 0) { throw "Failed: $w (exit $LASTEXITCODE)" }
}

# ----------------- Helpers -----------------
function To-WslPath([string]$WinPath){
  if([string]::IsNullOrWhiteSpace($WinPath)){ return "" }
  $drive = $WinPath.Substring(0,1).ToLower()
  $tail  = $WinPath.Substring(2) -replace '\\','/'   # <-- correct escaping
  return "/mnt/$drive/$tail"
}

# ----------------- Rotation -----------------
Log "===== BEGIN Key Rotation ====="
$Backup = Join-Path $SshDir ("backup-{0}" -f (Get-Date -Format "yyyyMMddHHmmss"))

Step { New-Item -ItemType Directory -Force -Path $Backup | Out-Null } "Create backup dir $Backup"

# Move any existing id_* keys into backup (non-fatal if none exist)
Step {
  Get-ChildItem $SshDir -Filter "id_*" -File -ErrorAction SilentlyContinue |
    Move-Item -Destination $Backup -Force -ErrorAction SilentlyContinue
} "Backup id_* to $Backup"

$KeyPath = Join-Path $SshDir "id_ed25519"

# Create a new ed25519 key (empty passphrase by default; change -N "" to prompt)
Step { ssh-keygen -t ed25519 -C "$($env:USERNAME)@$(hostname)" -f $KeyPath -N "" } "Generate new ed25519"

# Load into Windows agent (idempotent)
Step { ssh-add $KeyPath | Out-Null } "Load key into Windows ssh-agent"

# Show agent keys
Step { ssh-add -l } "List agent keys"

# Print paths for convenience
$PubWin = "$KeyPath.pub"; $PubWsl = To-WslPath $PubWin
Log "Public key (Windows): $PubWin"
Log "Public key (WSL):     $PubWsl"
Log "Tip: From WSL:  ssh-copy-id -i $PubWsl <host>"

Log "===== COMPLETE Key Rotation ====="
try { Stop-Transcript | Out-Null } catch {}
