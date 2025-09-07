#!/usr/bin/env bash
#
# Sets up the PowerShell 7 profile for Windows from a WSL2 environment.
#

set -euo pipefail

DRY_RUN=0
REQUIRE_SYMLINK=0
PREFER_SYMLINK=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --require-symlink) REQUIRE_SYMLINK=1 ;;
    --no-symlink) PREFER_SYMLINK=0 ;;
  esac
done

echo "🔧 Setting up PowerShell 7 (pwsh) Windows profile..."

# --- Pre-flight Checks ---
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
  echo "❌ This command is designed for WSL2 environments."
  echo "💡 Run this from WSL2 to set up your Windows PowerShell 7 profile."
  exit 1
fi

HAVE_PWSH=0; HAVE_POWERSHELL=0
if command -v pwsh.exe >/dev/null 2>&1; then HAVE_PWSH=1; fi
if command -v powershell.exe >/dev/null 2>&1; then HAVE_POWERSHELL=1; fi
if [[ $HAVE_PWSH -eq 0 && $HAVE_POWERSHELL -eq 0 ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "⚠️  Neither pwsh.exe nor powershell.exe appears available; proceeding with placeholders (dry-run)."
  else
    echo "❌ Neither pwsh.exe nor powershell.exe found on your Windows PATH."
    echo "💡 Install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases"
    exit 1
  fi
fi

# --- Determine Windows username ---
WIN_USER="${WIN_USER:-}"
if [[ -z "$WIN_USER" && $HAVE_PWSH -eq 1 ]]; then
  WIN_USER=$(pwsh.exe -NoProfile -NonInteractive -Command '$env:USERNAME' 2>/dev/null | tr -d '\r' || true)
fi
if [[ -z "$WIN_USER" && $HAVE_POWERSHELL -eq 1 ]]; then
  WIN_USER=$(powershell.exe -NoProfile -NonInteractive -Command '$env:USERNAME' 2>/dev/null | tr -d '\r' || true)
fi
if [[ -z "$WIN_USER" ]] && command -v cmd.exe >/dev/null 2>&1; then
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
fi
if [[ -z "$WIN_USER" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "⚠️  Could not determine Windows username; using placeholder (dry-run)."
    WIN_USER="User"
  else
    echo "❌ Could not determine Windows username via PowerShell or cmd.exe."
    echo '💡 Try running: powershell.exe -NoProfile -Command "$env:USERNAME" from WSL to verify.'
    exit 1
  fi
fi
echo "✅ Detected Windows user: $WIN_USER"

# --- Determine Windows profile path ($PROFILE) ---
PWSH7_PROFILE_WIN=""
if [[ $HAVE_PWSH -eq 1 ]]; then
  PWSH7_PROFILE_WIN=$(pwsh.exe -NoProfile -NonInteractive -Command '$PROFILE' 2>/dev/null | tr -d '\r' || true)
fi
if [[ -z "$PWSH7_PROFILE_WIN" ]]; then
  PWSH7_PROFILE_WIN="C:\\Users\\$WIN_USER\\Documents\\PowerShell\\Microsoft.PowerShell_profile.ps1"
fi

# Convert to WSL path
PWSH7_PROFILE_WSL=""
if command -v wslpath >/dev/null 2>&1; then
  PWSH7_PROFILE_WSL=$(wslpath -u "$PWSH7_PROFILE_WIN" 2>/dev/null || true)
fi
if [[ -z "$PWSH7_PROFILE_WSL" ]]; then
  PWSH7_PROFILE_WSL=$(printf '%s' "$PWSH7_PROFILE_WIN" | sed -e 's|^\([A-Za-z]\):|/mnt/\L\1|' -e 's|\\|/|g')
fi
PWSH7_PROFILE_DIR=$(dirname "$PWSH7_PROFILE_WSL")
echo "✅ Using PowerShell 7 profile path: $PWSH7_PROFILE_WSL"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "📝 (dry-run) Would ensure directory exists: $PWSH7_PROFILE_DIR"
else
  if [[ ! -d "$PWSH7_PROFILE_DIR" ]]; then
    mkdir -p "$PWSH7_PROFILE_DIR"
    echo "✅ Created profile directory: $PWSH7_PROFILE_DIR"
  fi
fi

# UNC path to this repo for Windows-side references
DOTFILES_WIN_PATH="\\\\wsl.localhost\\"${WSL_DISTRO_NAME}"\\home\\"${USER}"\\dotfiles"
PROJECTS_WIN_PATH="C:\\Users\\${WIN_USER}\\projects"

echo "🔗 Preparing to link Windows profile to repo profile (preferred)."

# Developer Mode check (symlinks without elevation)
if [[ $HAVE_POWERSHELL -eq 1 ]]; then
  DEV_MODE_STATUS=$(powershell.exe -NoProfile -NonInteractive -Command "try { (Get-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense } catch { '' }" 2>/dev/null | tr -d '\r' || true)
  if [[ -z "$DEV_MODE_STATUS" || "$DEV_MODE_STATUS" == "0" ]]; then
    echo "⚠️  Windows Developer Mode appears OFF; symlink may require elevation."
    echo "   Enable Settings → For Developers → Developer Mode for best results."
  fi
fi

# Try to create Windows symlink to repo profile; fallback to loader
CREATE_SYMLINK=1
if [[ $DRY_RUN -eq 1 ]]; then
  echo "📝 (dry-run) Would attempt to create Windows symlink: $PWSH7_PROFILE_WSL -> ${DOTFILES_WIN_PATH}\\PowerShell\\Microsoft.PowerShell_profile.ps1"
else
  PROFILE_PARENT_DIR=$(dirname "$PWSH7_PROFILE_WSL")
  if [[ ! -d "$PROFILE_PARENT_DIR" ]]; then
    mkdir -p "$PROFILE_PARENT_DIR" 2>/dev/null || true
  fi
  if [[ $PREFER_SYMLINK -eq 1 && $HAVE_POWERSHELL -eq 1 ]]; then
    if [[ -f "$PWSH7_PROFILE_WSL" && ! -L "$PWSH7_PROFILE_WSL" ]]; then
      rm -f "$PWSH7_PROFILE_WSL" 2>/dev/null || true
    fi
    powershell.exe -NoProfile -NonInteractive -Command "try { New-Item -ItemType SymbolicLink -Path \`"$PWSH7_PROFILE_WIN\`" -Target \`"${DOTFILES_WIN_PATH}\PowerShell\Microsoft.PowerShell_profile.ps1\`" -Force | Out-Null; exit 0 } catch { exit 1 }" >/dev/null 2>&1 || CREATE_SYMLINK=0
  else
    CREATE_SYMLINK=0
  fi
fi

if [[ $CREATE_SYMLINK -eq 0 ]]; then
  if [[ $REQUIRE_SYMLINK -eq 1 ]]; then
    echo "❌ Required symlink could not be created. Aborting (no loader fallback due to --require-symlink)." >&2
    exit 2
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "📝 (dry-run) Would write PowerShell loader profile to: $PWSH7_PROFILE_WSL"
  else
    # Build loader content once, with variables expanded here in Bash
    LOADER_CONTENT=$(cat <<EOF
# Windows PowerShell 7 Profile - Generated by dotfiles setup
# Created: $(date -Iseconds)
# This profile loads the main dotfiles PowerShell configuration from WSL2.

# Prefer \wsl.localhost, then legacy \\wsl$ fallback
\$roots = @(
  "$DOTFILES_WIN_PATH",
  "$DOTFILES_WIN_PATH" -replace '^\\\\\\\\wsl\.localhost', '\\\\wsl$'
)

# Resolve DOTFILES_ROOT and main profile
foreach (\$r in \$roots) {
  \$candidate = Join-Path \$r 'PowerShell\\Microsoft.PowerShell_profile.ps1'
  if (Test-Path \$candidate) {
    \$env:DOTFILES_ROOT = \$r
    break
  }
}
if (-not \$env:DOTFILES_ROOT) { \$env:DOTFILES_ROOT = "$DOTFILES_WIN_PATH" }
if (-not \$env:PROJECTS_ROOT) { \$env:PROJECTS_ROOT = "$PROJECTS_WIN_PATH" }

\$mainProfile = Join-Path \$env:DOTFILES_ROOT 'PowerShell\\Microsoft.PowerShell_profile.ps1'
if (Test-Path \$mainProfile) {
  try {
    . \$mainProfile
    Write-Host '✅ Loaded dotfiles PowerShell profile' -ForegroundColor Green
  } catch {
    Write-Warning '❌ Error loading dotfiles PowerShell profile:'
    Write-Warning \$_.Exception.Message
    Write-Host '💡 Falling back to basic configuration' -ForegroundColor Yellow
    function projects { Set-Location \$env:PROJECTS_ROOT }
  }
} else {
  Write-Warning ("Dotfiles main profile not found at: " + \$mainProfile)
  Write-Host '📦 Setting up basic configuration...' -ForegroundColor Yellow
  function projects { Set-Location \$env:PROJECTS_ROOT }
}
EOF
)

    # First attempt: write via WSL path (may fail on some setups)
    if ! printf '%s' "$LOADER_CONTENT" >"$PWSH7_PROFILE_WSL" 2>/dev/null; then
      echo "↪️  Could not write via /mnt/c (falling back to Windows-side write)"
      # Fallback: write using powershell.exe on the Windows side to avoid WSL I/O issues
      if [[ $HAVE_POWERSHELL -eq 1 || $HAVE_PWSH -eq 1 ]]; then
        # Base64 encode content (UTF-8) without line wraps
        CONTENT_B64=$(printf '%s' "$LOADER_CONTENT" | base64 | tr -d '\n')
        PSBIN="powershell.exe"; [[ $HAVE_PWSH -eq 1 ]] && PSBIN="pwsh.exe"
        "$PSBIN" -NoProfile -NonInteractive -Command "\
          try { \
            \$p = '$PWSH7_PROFILE_WIN'; \
            \$d = Split-Path -Parent \$p; \
            if (-not (Test-Path \$d)) { New-Item -ItemType Directory -Path \$d -Force | Out-Null } \
            \$b64 = '$CONTENT_B64'; \
            \$bytes = [Convert]::FromBase64String(\$b64); \
            \$text = [Text.Encoding]::UTF8.GetString(\$bytes); \
            [IO.File]::WriteAllText(\$p, \$text, [Text.Encoding]::UTF8); \
            exit 0 \
          } catch { exit 1 }" >/dev/null 2>&1 || {
            echo "❌ Failed to write Windows PowerShell profile via powershell.exe" >&2
            exit 1
          }
      else
        echo "❌ Neither powershell.exe nor pwsh.exe available for Windows-side write" >&2
        exit 1
      fi
    fi
    echo "✅ Created PowerShell 7 loader profile."
  fi
elif [[ $DRY_RUN -eq 0 ]]; then
  echo "✅ Created Windows symlink to project profile."
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo ""
  echo "🧪 (dry-run) Verification plan:"
  echo "  • Check pwsh.exe available"
  echo "  • Resolve Windows profile path via pwsh: '$PWSH7_PROFILE_WIN'"
  echo "  • Verify main profile path exists in WSL: '$DOTFILES_WIN_PATH\\PowerShell\\Microsoft.PowerShell_profile.ps1' (from Windows)"
  echo "  • Confirm oh-my-posh installed on Windows"
  echo ""
  echo "✅ Dry run complete. No changes were made."
else
  echo ""
  echo "🧪 Testing PowerShell 7 profile..."
  if [[ $HAVE_PWSH -eq 1 ]]; then
    pwsh.exe -NoProfile -NonInteractive -Command "
        \$WarningPreference = 'SilentlyContinue'
        Write-Host '--- PowerShell Profile Test ---'
        \$profilePath = \$PROFILE
        Write-Host ('Profile path according to \$PROFILE: ' + \$profilePath)
        if (Test-Path \$profilePath) {
            Write-Host '✅ Profile file exists' -ForegroundColor Green
            try {
                \$first = Get-Content -Path \$profilePath -TotalCount 1 -ErrorAction SilentlyContinue
                if (\$first -match 'Windows PowerShell 7 Profile - Generated') {
                    Write-Host 'ℹ️ Detected loader profile content' -ForegroundColor DarkGray
                }
            } catch { }
        } else {
            Write-Host '❌ Profile not found at expected path' -ForegroundColor Red
        }

        # Validate repo main profile exists and is not a loader to avoid recursion
        \$repoRoot = '${DOTFILES_WIN_PATH}'
        \$main = Join-Path \$repoRoot 'PowerShell\\Microsoft.PowerShell_profile.ps1'
        if (Test-Path \$main) {
            Write-Host '✅ Repo main profile found' -ForegroundColor Green
            try {
                \$l1 = Get-Content -Path \$main -TotalCount 1 -ErrorAction SilentlyContinue
                if (\$l1 -match 'Windows PowerShell 7 Profile - Generated') {
                    Write-Warning 'Repo main profile appears to be a loader (would recurse). Please restore it from backup.'
                }
            } catch { }
        } else {
            Write-Warning ('Repo main profile not found at: ' + \$main)
        }
        # Basic function presence check by dot-sourcing main profile directly
        if (Test-Path \$main) {
            try {
                . \$main
                \$codeFn = Get-Command code -CommandType Function -ErrorAction SilentlyContinue
                \$wslcodeFn = Get-Command wslcode -CommandType Function -ErrorAction SilentlyContinue
                if (\$codeFn) { Write-Host '✅ code function available' -ForegroundColor Green } else { Write-Warning 'code function not found' }
                if (\$wslcodeFn) { Write-Host '✅ wslcode function available' -ForegroundColor Green } else { Write-Warning 'wslcode function not found' }
            } catch {
                Write-Warning ('Error loading main profile for verification: ' + $_.Exception.Message)
            }
        }
        Write-Host '--- End Test ---'
    "
  else
    echo "⚠️  Skipping profile test (pwsh.exe unavailable)"
  fi
  echo "🎉 PowerShell 7 setup complete!"
fi
