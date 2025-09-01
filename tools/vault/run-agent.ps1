param(
  [string]$VaultAddr = $env:VAULT_ADDR,
  [string]$Role = $(if ($env:VAULT_ROLE) { $env:VAULT_ROLE } else { 'dev-shell' }),
  [string]$AuthMethod = $(if ($env:VAULT_AUTH_METHOD) { $env:VAULT_AUTH_METHOD } else { 'oidc' }),
  [string]$SinkPath = $(
    if ($env:VAULT_SINK_PATH) { $env:VAULT_SINK_PATH }
    elseif ($IsWindows) { Join-Path $env:LOCALAPPDATA 'vault\dotfiles.env' }
    else { Join-Path $HOME '.cache/vault/dotfiles.env' }
  ),
  [string]$LogLevel = $(if ($env:VAULT_AGENT_LOG) { $env:VAULT_AGENT_LOG } else { 'info' }),
  [string]$Namespace = $env:VAULT_NAMESPACE
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $VaultAddr) {
  Write-Error 'VAULT_ADDR is required (e.g., https://vault.example.com)'
}

if (-not (Get-Command vault -ErrorAction SilentlyContinue)) {
  Write-Error 'vault CLI not found in PATH'
}

$sinkDir = Split-Path -Parent $SinkPath
New-Item -ItemType Directory -Force -Path $sinkDir | Out-Null

$config = @"
auto_auth {
  method "$AuthMethod" {
    mount_path = "auth/$AuthMethod"
    config = { role = "$Role" }
  }
  sink "file" {
    config = {
      path = "$SinkPath"
      format = "env"
    }
  }
}

vault { address = "$VaultAddr" }
log_level = "$LogLevel"
"@
if ($Namespace) { $config += "`nnamespace = `"$Namespace`"" }

$tmp = New-TemporaryFile
try {
  Set-Content -Path $tmp -Value $config -Encoding ASCII
  Write-Host "🟢 Starting Vault Agent with sink: $SinkPath" -ForegroundColor Green
  Write-Host "ℹ️  Config: $tmp" -ForegroundColor Cyan
  Write-Host "ℹ️  Addr:   $VaultAddr  Role: $Role  Method: $AuthMethod" -ForegroundColor Cyan
  & vault agent -config "$tmp"
}
finally {
  Remove-Item -Force -ErrorAction SilentlyContinue $tmp
}
