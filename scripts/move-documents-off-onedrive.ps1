<#
.SYNOPSIS
  Move Windows "Documents" off OneDrive and point PowerShell 7 $PROFILE to the WSL repo.

.DESCRIPTION
  - Updates registry so Documents points to %USERPROFILE%\Documents
  - Optionally migrates files from OneDrive\(Documents|MyDocuments) to local Documents
  - Creates a symlink (preferred) or writes a loader profile at $PROFILE pointing to the repo
  - Requires elevation for registry and symlink operations

.PARAMETER DryRun
  Print the plan without making changes.

.PARAMETER Migrate
  Move files from OneDrive Documents to local Documents (best-effort).

.PARAMETER RequireSymlink
  Fail if a symlink cannot be created (no loader fallback).

.EXAMPLE
  # Elevated PowerShell
  .\scripts\move-documents-off-onedrive.ps1 -Migrate -RequireSymlink
#>
param(
  [switch]$DryRun,
  [switch]$Migrate,
  [switch]$RequireSymlink
)

$ErrorActionPreference = 'Stop'

function Write-Plan($msg) { Write-Host "PLAN: $msg" -ForegroundColor DarkGray }
function Write-Ok($msg)   { Write-Host "OK: $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Warning $msg }

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Warn "Run this script in an elevated PowerShell (Run as Administrator)."
  if (-not $DryRun) { throw "Elevation required" }
}

$user = $env:USERNAME
$userProfile = $env:USERPROFILE
$docsLocal = Join-Path $userProfile 'Documents'
$docsPowerShell = Join-Path $docsLocal 'PowerShell'
$oneDriveDocsCandidates = @(
  (Join-Path $userProfile 'OneDrive\Documents'),
  (Join-Path $userProfile 'OneDrive\MyDocuments')
)

$regUserShell = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$regShell     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'

$currentUserShell = (Get-ItemProperty -Path $regUserShell -ErrorAction SilentlyContinue).Personal
$currentShell     = (Get-ItemProperty -Path $regShell -ErrorAction SilentlyContinue).Personal

$targetUserShell = '%USERPROFILE%\Documents'
$targetShell     = "$userProfile\Documents"

Write-Host "Moving Documents off OneDrive (user: $user)" -ForegroundColor Cyan
if ($DryRun) {
  Write-Plan "Would set $regUserShell:Personal = $targetUserShell (was: $currentUserShell)"
  Write-Plan "Would set $regShell:Personal     = $targetShell (was: $currentShell)"
} else {
  # Ensure keys exist
  New-Item -Path $regUserShell -Force | Out-Null
  New-Item -Path $regShell -Force | Out-Null
  # Set registry
  try {
    New-ItemProperty -Path $regUserShell -Name Personal -Value $targetUserShell -PropertyType ExpandString -Force | Out-Null
  } catch { Set-ItemProperty -Path $regUserShell -Name Personal -Value $targetUserShell }
  Set-ItemProperty -Path $regShell -Name Personal -Value $targetShell
  Write-Ok "Updated Documents path in registry"
}

if ($DryRun) {
  Write-Plan "Would ensure local path exists: $docsLocal"
  Write-Plan "Would ensure local path exists: $docsPowerShell"
} else {
  New-Item -ItemType Directory -Path $docsLocal -Force | Out-Null
  New-Item -ItemType Directory -Path $docsPowerShell -Force | Out-Null
}

if ($Migrate) {
  foreach ($cand in $oneDriveDocsCandidates) {
    if (Test-Path $cand) {
      if ($DryRun) {
        Write-Plan "Would migrate contents: $cand -> $docsLocal"
      } else {
        try {
          Write-Host "Migrating contents from $cand to $docsLocal" -ForegroundColor Yellow
          robocopy.exe "$cand" "$docsLocal" /E /MOVE /COPY:DAT /R:1 /W:1 | Out-Null
          Write-Ok "Migration finished from: $cand"
        } catch {
          Write-Warn "Migration issue: $($_.Exception.Message)"
        }
      }
    }
  }
}

# Prepare $PROFILE at local Documents\PowerShell
$profilePath = Join-Path $docsPowerShell 'Microsoft.PowerShell_profile.ps1'
$repoProfile = "\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles\PowerShell\Microsoft.PowerShell_profile.ps1"

if ($DryRun) {
  Write-Plan "Would create symlink: $profilePath -> $repoProfile (preferred)"
}

$createdSymlink = $false
if (-not $DryRun) {
  try {
    if (Test-Path $profilePath) {
      $existing = Get-Item $profilePath -ErrorAction SilentlyContinue
      if ($existing -and -not $existing.LinkType) { Remove-Item -Path $profilePath -Force -ErrorAction SilentlyContinue }
    }
    New-Item -ItemType SymbolicLink -Path $profilePath -Target $repoProfile -Force | Out-Null
    Write-Ok "Created symlink: $profilePath -> $repoProfile"
    $createdSymlink = $true
  } catch {
    Write-Warn "Could not create symlink (may require Developer Mode or elevation): $($_.Exception.Message)"
    $createdSymlink = $false
  }
}

if (-not $createdSymlink) {
  if ($RequireSymlink) { throw "Required symlink could not be created" }
  if ($DryRun) {
    Write-Plan "Would write loader profile to: $profilePath"
  } else {
    @"
# Windows PowerShell 7 Profile - Loader (no OneDrive)




${env:DOTFILES_ROOT} = "\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles"
$main = Join-Path ${env:DOTFILES_ROOT} 'PowerShell\Microsoft.PowerShell_profile.ps1'
try { . $main } catch { Write-Warning $_.Exception.Message }
"@ | Set-Content -Path $profilePath -Encoding utf8
    Write-Ok "Wrote loader profile at: $profilePath"
  }
}

Write-Host "Documents path updated. You may need to sign out/in for shell folders to refresh." -ForegroundColor Cyan
Write-Host "Then open a new PowerShell 7 window to take effect." -ForegroundColor Yellow
