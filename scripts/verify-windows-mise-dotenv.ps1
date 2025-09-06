<#
  .SYNOPSIS
    Verify Mise activation and dotenv loading for Windows PowerShell sessions.

  .DESCRIPTION
    - Prints Mise version if available and attempts activation via `mise activate pwsh --shims`.
    - Loads `.env` files using the repo loader if present and reports key samples.
    - Confirms quiet logging defaults (DIRENV_LOG_FORMAT).
    - Non-fatal: exits 0, prints warnings for missing components.

  .NOTES
    Intended to be invoked from WSL with `just verify-windows-mise-dotenv` or run directly in Windows PowerShell.
#>

$ErrorActionPreference = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'

Write-Host "=== Verify: Mise + dotenv (Windows PowerShell) ===" -ForegroundColor Cyan

# 1) Mise presence and activation
if (Get-Command mise -ErrorAction SilentlyContinue) {
  Write-Host ("Mise version: " + (mise --version))
  try {
    (& mise activate pwsh --shims) | Invoke-Expression
    Write-Host "Mise activation attempted (pwsh shims)" -ForegroundColor Green
  } catch {
    Write-Warning ("Mise activation failed: " + $_.Exception.Message)
  }
} else {
  Write-Warning "mise not found on PATH"
}

# 2) Quiet logging default
if (-not $env:DIRENV_LOG_FORMAT) { $env:DIRENV_LOG_FORMAT = '' }
Write-Host ("DIRENV_LOG_FORMAT='" + $env:DIRENV_LOG_FORMAT + "'")

# 3) Dotenv loader
try {
  $root = $env:DOTFILES_ROOT
  if (-not $root -or [string]::IsNullOrWhiteSpace($root)) {
    # Best-effort: infer from this script's location if running from repo
    $scriptDir = Split-Path -Parent $PSCommandPath
    $root = Split-Path -Parent $scriptDir
  }
  $loader = Join-Path $root 'PowerShell/Utils/Load-Env.ps1'
  if (Test-Path $loader) {
    . $loader
    if (Get-Command -Name Activate-Mise -ErrorAction SilentlyContinue) { Activate-Mise }
    $rootEnv = Join-Path $root '.env'
    $mcpEnv = Join-Path (Join-Path $root 'mcp') '.env'
    if (Test-Path $rootEnv) { Load-EnvFile -FilePath $rootEnv }
    if (Test-Path $mcpEnv) { Load-EnvFile -FilePath $mcpEnv }
    # Report a few sample keys if present
    $keys = @('FOO','MCP_ONLY','PROJECTS_ROOT','DOTFILES_ROOT')
    foreach ($k in $keys) {
      $v = (Get-Item -Path "env:$k" -ErrorAction SilentlyContinue).Value
      if ($null -eq $v) { $v = '' }
      Write-Host ("ENV $k=" + $v)
    }
  } else {
    Write-Warning "Load-Env.ps1 not found; skipping dotenv check"
  }
} catch {
  Write-Warning ("Dotenv verification error: " + $_.Exception.Message)
}

exit 0

