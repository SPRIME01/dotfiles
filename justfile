# Justfile for dotfiles project

# Display a list of available tasks when no target is specified.
default:
	@echo "=== SSH Agent Bridge (pinned) ==="
	@just ssh-bridge-help
	@echo ""
	@just --list

test:
	@bash scripts/run-tests.sh

# Lint shell scripts (shellcheck) and verify formatting (shfmt diff mode)
lint:
	@bash tools/lint.sh

# Auto-format shell scripts in-place using shfmt
format:
	@shfmt -w .

# Install direnv across supported platforms (idempotent)
install-direnv:
	@bash -c 'set -euo pipefail; echo "🌱 Installing direnv..."; if command -v direnv >/dev/null 2>&1; then echo "✅ direnv already installed: $$(command -v direnv)"; direnv version || true; exit 0; fi; OS=$$(uname -s); if command -v apt >/dev/null 2>&1; then echo "📦 Using apt"; sudo apt update -y >/dev/null 2>&1 || true; sudo apt install -y direnv; elif command -v brew >/dev/null 2>&1; then echo "🍺 Using Homebrew"; brew install direnv; elif command -v dnf >/dev/null 2>&1; then echo "📦 Using dnf"; sudo dnf install -y direnv; elif command -v pacman >/dev/null 2>&1; then echo "📦 Using pacman"; sudo pacman -Sy --noconfirm direnv; elif command -v zypper >/dev/null 2>&1; then echo "📦 Using zypper"; sudo zypper install -y direnv; elif command -v scoop >/dev/null 2>&1; then echo "🪟 Using scoop (Windows)"; scoop install direnv; elif command -v choco >/dev/null 2>&1; then echo "🪟 Using choco (Windows)"; choco install direnv -y; else echo "❌ No supported package manager found. Install manually from https://direnv.net"; exit 1; fi; if command -v direnv >/dev/null 2>&1; then echo "🎉 direnv installed: $$(direnv version)"; echo "💡 Create a .envrc in a project and run: direnv allow"; echo "💡 To disable temporarily: export DISABLE_DIRENV=1"; else echo "❌ direnv installation appears to have failed"; exit 1; fi'

# Vault Agent helpers
vault-agent-example:
	@bash -c 'set -e; mkdir -p tools/vault; cp tools/vault/agent.hcl.example /tmp/agent.hcl; echo "Example written to /tmp/agent.hcl"'

vault-agent-run:
	@bash -c 'set -e; if ! command -v vault >/dev/null 2>&1; then echo "❌ vault CLI not found"; exit 1; fi; chmod +x tools/vault/run-agent.sh; VAULT_ADDR=${VAULT_ADDR:-} tools/vault/run-agent.sh'

vault-agent-run-demo:
	@bash -c 'set -e; if ! command -v vault >/dev/null 2>&1; then echo "❌ vault CLI not found"; exit 1; fi; chmod +x tools/vault/run-agent.sh; echo "Using demo settings (you must set VAULT_ADDR)"; VAULT_ROLE=${VAULT_ROLE:-dev-shell} VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-oidc} tools/vault/run-agent.sh'

# Windows/PowerShell runner
vault-agent-run-windows:
	@bash -c 'set -e; if ! command -v pwsh >/dev/null 2>&1; then echo "❌ pwsh (PowerShell 7) not found"; exit 1; fi; pwsh -NoProfile -File tools/vault/run-agent.ps1'

# Launch the interactive setup wizard for Unix shells.
# Guides you through configuring shells and installing optional components like VS Code settings.
setup:
	@bash scripts/setup-wizard.sh

# Dry-run the setup wizard (no changes, shows planned actions)
setup-dry-run:
	@bash scripts/setup-wizard.sh --dry-run

# Install optional dependencies (socat, openssh-client/server) with systemd guard
install-deps:
	@bash scripts/install-dependencies.sh

# Interactive setup wizard (Windows via PowerShell 7)
setup-windows:
	@pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup-wizard.ps1

# Safe update: stash local changes, pull main, re-bootstrap, restore stash
update:
	@bash update.sh

# Environment diagnostics (doctor)
doctor:
	@bash scripts/doctor.sh

doctor-verbose:
	@bash scripts/doctor.sh --verbose

doctor-strict:
	@bash scripts/doctor.sh --strict --verbose

# Bootstrap/apply dotfiles via chezmoi (wrapper around install.sh)
install:
	@bash -lc 'set -euo pipefail; echo "🚀 Running install.sh (chezmoi apply)..."; bash install.sh'

# Dry-run the bootstrap (no changes; shows diff)
install-dry-run:
	@bash -lc 'set -euo pipefail; echo "🧪 Dry-run install.sh (no changes)..."; DRY_RUN=1 bash install.sh'

# Set up projects directory and Windows symlink (WSL2 only)
setup-projects:
	@bash scripts/setup-projects-idempotent.sh

# Set up PowerShell 7 profile for Windows (requires PowerShell 7 installed)
# Usage: `just setup-pwsh7` (run from WSL)
setup-pwsh7:
	@bash -lc 'set -euo pipefail; echo "🪟 Setting up PowerShell 7 profile for Windows..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; echo "💡 Run from WSL to configure the Windows-side PowerShell profile."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."; echo "💡 Ensure Windows PowerShell or PowerShell 7 is installed and accessible."; exit 1; fi; bash scripts/setup-pwsh7.sh'

setup-pwsh7-dry-run:
	@bash -lc 'set -euo pipefail; echo "🪟(dry-run) Setting up PowerShell 7 profile for Windows..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."; exit 0; fi; bash scripts/setup-pwsh7.sh --dry-run'

# Force symlink for Windows $PROFILE (fails if symlink can't be created)
setup-pwsh7-symlink:
	@bash -lc 'set -euo pipefail; echo "🪟 Forcing Windows $PROFILE symlink..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."; exit 1; fi; bash scripts/setup-pwsh7.sh --require-symlink'

# Windows Developer Mode helpers (run from WSL)

# Windows Developer Mode helpers (run from WSL)
devmode-status:
	@bash -c 'powershell.exe -NoProfile -NonInteractive -Command "try { $v=(Get-ItemProperty -Path ''HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'' -Name ''AllowDevelopmentWithoutDevLicense'' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense; if($v -eq 1){Write-Output ''Developer Mode: Enabled''} elseif($v -eq 0){Write-Output ''Developer Mode: Disabled''} else {Write-Output ''Developer Mode: Unknown''} } catch { Write-Output ''Developer Mode: Unknown'' }" | tr -d "\r"'

devmode-enable:
	@bash -c 'echo "⚠️  Attempting to enable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\SOFTWARE\\\\CurrentVersion\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 1; Write-Host ''''Developer Mode enabled'''' -ForegroundColor Green\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

devmode-disable:
	@bash -c 'echo "⚠️  Attempting to disable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\SOFTWARE\\\\CurrentVersion\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 0; Write-Host ''''Developer Mode disabled'''' -ForegroundColor Yellow\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

# Force symlink via elevated Windows PowerShell (UAC prompt expected)
setup-pwsh7-symlink-admin:
	@bash -lc 'set -euo pipefail; echo "🪟 Forcing Windows $PROFILE symlink via elevated PowerShell (UAC prompt expected)..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not available from WSL."; exit 1; fi; SCRIPT_WIN=$(wslpath -w "$PWD/scripts/invoke-elevated-symlink.ps1"); TARGET_WIN=$(wslpath -w "$PWD/PowerShell/Microsoft.PowerShell_profile.ps1"); echo "🔗 Script: ${SCRIPT_WIN}"; echo "🎯 Target: ${TARGET_WIN}"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_WIN" -Target "$TARGET_WIN"'
	@bash -lc 'set -euo pipefail; echo "🪟 Forcing Windows $PROFILE symlink via elevated PowerShell (UAC prompt expected)..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not available from WSL."; exit 1; fi; SCRIPT_WIN=$(wslpath -w "$PWD/scripts/invoke-elevated-symlink.ps1"); TARGET_WIN=$(wslpath -w "$PWD/PowerShell/Microsoft.PowerShell_profile.ps1"); echo "🔗 Script: ${SCRIPT_WIN}"; echo "🎯 Target: ${TARGET_WIN}"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_WIN" -Target "$TARGET_WIN"'

# Verify Windows PowerShell profile links to this repo and theme resolves
# Usage: `just verify-windows-profile` (run from WSL)
verify-windows-profile:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This verification targets WSL; run from WSL."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then echo "❌ Neither powershell.exe nor pwsh.exe available from WSL."; exit 1; fi; bash scripts/verify-windows-profile.sh'

# Verify Oh My Posh theme resolution and binary availability on Windows
# Usage: `just verify-windows-theme` (run from WSL)
verify-windows-theme:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This verification targets WSL; run from WSL."; exit 0; fi; if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then echo "❌ Neither powershell.exe nor pwsh.exe available from WSL."; exit 1; fi; bash scripts/verify-windows-theme.sh'

# Verify Mise activation + dotenv loading in Windows PowerShell
# Usage: `just verify-windows-mise-dotenv` (run from WSL)
verify-windows-mise-dotenv:
	@bash -lc 'set -euo pipefail; \
	  if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then \
	    echo "ℹ️  Run from WSL to verify Windows PowerShell environment."; \
	    exit 0; \
	  fi; \
	  if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then \
	    echo "❌ Neither powershell.exe nor pwsh.exe available from WSL."; \
	    exit 1; \
	  fi; \
	  WIN_PATH=$(wslpath -w "$PWD/scripts/verify-windows-mise-dotenv.ps1"); \
	  if command -v pwsh.exe >/dev/null 2>&1; then \
	    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" | tr -d "\r"; \
	  else \
	    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" | tr -d "\r"; \
	  fi'

# List available Oh My Posh themes on Windows
# Usage: `just list-windows-themes` (run from WSL)
list-windows-themes:
	@bash -c '
	set -euo pipefail
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "ℹ️  list-windows-themes is intended for WSL; skipping on non-WSL systems."
	exit 0
	fi

	UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}$(pwd | sed "s|^/|\\\\|; s|/|\\\\|g")"

	PSBIN="pwsh.exe"; command -v pwsh.exe >/dev/null 2>&1 || PSBIN="powershell.exe"
	"$PSBIN" -NoProfile -NonInteractive -Command "\
	if (-not \$env:DOTFILES_ROOT -or [string]::IsNullOrWhiteSpace(\$env:DOTFILES_ROOT)) { \$env:DOTFILES_ROOT = \"$UNC\" } ; \
	\$themes = Get-ChildItem -LiteralPath (Join-Path \$env:DOTFILES_ROOT 'PowerShell\\Themes') -Filter *.omp.json -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name ; \
	if (\$themes) { \$themes | ForEach-Object { Write-Host (\" - \" + \$_) } } else { Write-Warning \"No themes found\" }\
	" | tr -d "\r"
	'

# Set OMP_THEME for Windows (persistent) and reinitialize current pwsh if present
# Usage: just set-windows-theme powerlevel10k_modern
set-windows-theme THEME:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  set-windows-theme is intended for WSL; skipping on non-WSL systems."; exit 0; fi; UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}$(pwd | sed "s|^/|\\\\|; s|/|\\\\|g")"; T="{{THEME}}"; if [[ -z "$T" || ! "$T" =~ ^[A-Za-z0-9._-]+(\.omp\.json)?$ ]]; then echo "❌ Invalid theme name: $T"; exit 2; fi; THEME_STR="$T"; PSBIN="pwsh.exe"; command -v pwsh.exe >/dev/null 2>&1 || PSBIN="powershell.exe"; "$PSBIN" -NoProfile -Command "\$t = '$THEME_STR'; if (-not \$t) { Write-Error 'Missing theme name'; exit 1 }; if (\$t -notmatch '\\.omp\\.json$') { \$t = \$t + '.omp.json' }; \$root = \$env:DOTFILES_ROOT; if ([string]::IsNullOrWhiteSpace(\$root)) { \$root = '$UNC' }; \$themePath = Join-Path \$root (Join-Path 'PowerShell\\Themes' \$t); if (-not (Test-Path \$themePath)) { Write-Error ('Theme not found: ' + \$themePath); exit 2 }; try { Set-ItemProperty -Path 'HKCU:\\Environment' -Name 'OMP_THEME' -Value \$t -ErrorAction Stop } catch { }; [Environment]::SetEnvironmentVariable('OMP_THEME', \$t, 'User') | Out-Null; Write-Host ('✅ Set OMP_THEME=' + \$t) -ForegroundColor Green; if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { try { oh-my-posh init pwsh --config \$themePath | Invoke-Expression; Write-Host '🎨 Reinitialized prompt for this shell' -ForegroundColor Green } catch { Write-Warning \$_.Exception.Message } } else { Write-Warning 'oh-my-posh not found on PATH' }"';
	@just setup-projects
	@echo ""
	@just setup-pwsh7
	@echo ""
	@echo "🎉 Windows integration setup complete!"
	@echo "💡 You now have:"
	@echo "   • Projects directory with Windows access"
	@echo "   • PowerShell 7 profile with dotfiles integration"
	@echo "   • WSL-Windows symlinks and functions"
	@echo ""
	@echo "(SSH agent integration removed)"

# Move Windows Documents off OneDrive and point $PROFILE to the repo (elevated)
move-docs-off-onedrive-admin:
	@bash scripts/run-move-docs-admin.sh

move-docs-off-onedrive-dry:
	@bash scripts/run-move-docs-dry.sh

# ===== PowerShell aliases/profile helpers (namespaced) =====

# Idempotent: regenerate module and profile section
# (the minimal pwsh-update recipe was removed intentionally)
pwsh-update-dry-run:
	@bash -lc 'set -euo pipefail; pwsh -NoLogo -NoProfile -File "PowerShell/Modules/Aliases/Update-AliasesModule.ps1" -WhatIf'

pwsh-reload-dry-run:
	@bash -lc 'set -euo pipefail; ROOT="$(pwd)"; echo "pwsh -NoLogo -NoProfile -File '$ROOT/PowerShell/Modules/Aliases/Update-AliasesModule.ps1'"; echo "pwsh -NoLogo -NoProfile -NoExit -Command \"Import-Module '$ROOT/PowerShell/Modules/Aliases/Aliases.psm1' -Force; . '$ROOT/PowerShell/Microsoft.PowerShell_profile.ps1'\""'

ps-help:
	@echo "=== PowerShell (repo) ==="
	@echo "  just pwsh-update           # Regenerate Aliases + profile"
	@echo "  just pwsh-reload           # Open pwsh with repo profile"
	@echo "  just pwsh-reload-windows   # From WSL, open Windows pwsh"
	@echo "  just pwsh-update-dry-run   # WhatIf regeneration"
	@echo "  just pwsh-reload-dry-run   # Print commands"

# --- PowerShell Aliases/Profile helpers ---

# Regenerate the Aliases module and profile lazy-loading section (idempotent)
pwsh-update:
	@bash -lc 'set -euo pipefail; if ! command -v pwsh >/dev/null 2>&1; then echo "❌ pwsh (PowerShell 7) not found on PATH" >&2; echo "💡 Install PowerShell 7 and ensure 'pwsh' is available" >&2; exit 1; fi; echo "🔁 Regenerating Aliases module and profile section..."; pwsh -NoLogo -NoProfile -File "PowerShell/Modules/Aliases/Update-AliasesModule.ps1"; echo "✅ Regeneration complete"'

# Open a new Linux/WSL PowerShell session with this repo's module and profile loaded
pwsh-reload:
	@bash -lc 'set -euo pipefail; if ! command -v pwsh >/dev/null 2>&1; then echo "❌ pwsh (PowerShell 7) not found on PATH" >&2; exit 1; fi; ROOT="$(pwd)"; echo "🔁 Updating module before loading..."; pwsh -NoLogo -NoProfile -File "PowerShell/Modules/Aliases/Update-AliasesModule.ps1"; echo "🚀 Launching PowerShell with repo profile loaded..."; pwsh -NoLogo -NoProfile -NoExit -Command "Import-Module '$ROOT/PowerShell/Modules/Aliases/Aliases.psm1' -Force; . '$ROOT/PowerShell/Microsoft.PowerShell_profile.ps1'; Write-Host '✅ Loaded aliases and profile from $ROOT' -ForegroundColor Green"'

# From WSL, open a Windows PowerShell (or PowerShell 7) session with this repo loaded via UNC
pwsh-reload-windows:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  Not running inside WSL; this recipe is intended for WSL." >&2; exit 0; fi; if ! command -v pwsh.exe >/dev/null 2>&1 && ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ Neither pwsh.exe nor powershell.exe available from WSL" >&2; exit 1; fi; UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}$(pwd | sed 's|^/|\\|; s|/|\\|g')"; PSBIN="pwsh.exe"; command -v pwsh.exe >/dev/null 2>&1 || PSBIN="powershell.exe"; echo "🔁 Updating module before loading (from WSL)..."; if command -v pwsh >/dev/null 2>&1; then pwsh -NoLogo -NoProfile -File "PowerShell/Modules/Aliases/Update-AliasesModule.ps1"; else echo "ℹ️ pwsh (Linux) not found; skipping module update"; fi; echo "🚀 Launching Windows $PSBIN with repo profile loaded from: $UNC"; "$PSBIN" -NoLogo -NoProfile -NoExit -Command "Import-Module '$UNC\\PowerShell\\Modules\\Aliases\\Aliases.psm1' -Force; . '$UNC\\PowerShell\\Microsoft.PowerShell_profile.ps1'; Write-Host '✅ Loaded aliases and profile from $UNC' -ForegroundColor Green"'

# Fix PowerShell 7 profile if it's not working correctly
fix-pwsh7:
	@echo "🔧 Diagnosing and fixing PowerShell 7 profile issues..."
	@just setup-pwsh7

# Clean up old PowerShell profiles that might conflict
clean-old-powershell-profiles:
	@bash -lc 'set -euo pipefail; echo "🧹 Cleaning up old PowerShell profiles..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."; echo "💡 Run from WSL if you want to clean Windows-side PowerShell profiles."; exit 0; fi; PWSH7_PROFILE=""; if command -v pwsh.exe >/dev/null 2>&1; then PWSH7_PROFILE=$(pwsh.exe -NoProfile -Command "$PROFILE" 2>/dev/null | tr -d "\r" || true); elif command -v powershell.exe >/dev/null 2>&1; then PWSH7_PROFILE=$(powershell.exe -NoProfile -Command "$PROFILE" 2>/dev/null | tr -d "\r" || true); else echo "❌ Neither pwsh.exe nor powershell.exe found on the Windows side."; echo "💡 Install PowerShell (pwsh) or ensure Windows PowerShell is available."; exit 0; fi; if [[ -n "${PWSH7_PROFILE}" ]]; then PWSH7_PROFILE_WSL=$(printf "%s" "${PWSH7_PROFILE}" | sed -E -e "s|^([A-Za-z]):\\\\\\\\|/mnt/\L\1/|" -e "s|\\\\\\\\|/|g"); if [[ -f "${PWSH7_PROFILE_WSL}" ]]; then BACKUP_NAME="${PWSH7_PROFILE_WSL}.backup.$(date +%Y%m%d_%H%M%S)"; mv "${PWSH7_PROFILE_WSL}" "${BACKUP_NAME}"; echo "✅ Backed up profile to: ${BACKUP_NAME}"; else echo "ℹ️  No existing PowerShell 7 profile found at ${PWSH7_PROFILE}"; fi; else echo "❌ Could not determine PowerShell profile path from Windows PowerShell"; echo "💡 Try launching PowerShell on Windows and check $PROFILE there."; fi; echo "🎉 PowerShell profile cleanup complete!"'

# Diagnose shell startup issues
diagnose-shell:
	@bash scripts/diagnose-shell.sh

# Fix environment loading issues
fix-env-loading:
	@bash scripts/fix-env-loading.sh

# Check for and fix alias/function conflicts
fix-alias-conflicts:
	@bash scripts/fix-alias-conflicts.sh

# Set up WSL2 for remote access via SSH and VS Code
setup-wsl2-remote:
	@bash -lc 'echo "🌐 Setting up WSL2 for remote access..."; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This command must be run from WSL2"; exit 1; fi; ./scripts/setup-wsl2-remote-access.sh; echo ""; echo "🎉 WSL2 remote access setup complete!"; echo "💡 Don't forget to run the Windows configuration script as Administrator"'

# Configure Windows for WSL2 remote access (run the PowerShell script from WSL; uses wslpath -w)
setup-wsl2-remote-windows:
	@bash -lc 'set -euo pipefail; \
	  if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This recipe must be run inside WSL"; exit 1; fi; \
	  if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (ensure Windows PowerShell is accessible from WSL)"; exit 1; fi; \
	  SCRIPT_WIN=$(wslpath -w "$PWD/scripts/setup-wsl2-remote-windows.ps1"); \
	  echo "🪟 Launching Windows remote access configuration script: $SCRIPT_WIN"; \
	  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_WIN"'

# Complete WSL2 remote setup (guided setup with all configuration)
setup-wsl2-complete:
	@bash scripts/setup-remote-development.sh

# Guided remote development setup (alias for setup-wsl2-complete)
setup-remote-dev: setup-wsl2-complete

# Run interactive wizard
run-wizard:
	@bash scripts/setup-wizard.sh --interactive

# Ensure key scripts are executable in the git index (fixes CI / local runs)
fix-permissions:
	@echo "🔧 Ensuring executable bits for known scripts..."
	@chmod +x tools/lint.sh scripts/install-dependencies.sh scripts/setup-pwsh7.sh || true
	@git update-index --chmod=+x tools/lint.sh scripts/install-dependencies.sh scripts/setup-pwsh7.sh >/dev/null 2>&1 || true
	@echo "✅ Permissions updated (if running in a git repo)."


# ============================================================================
# SSH Agent Bridge (WSL2 ↔ Windows)
# Helpers around scripts in ssh-agent-bridge/
# ============================================================================

ssh-bridge-help:
	@echo "SSH Agent Bridge commands:"
	@echo "  just ssh-bridge-preflight                 # Check manifest, npiperelay, agent keys"
	@echo "  just ssh-bridge-install-windows           # Configure Windows ssh-agent + manifest"
	@echo "  just ssh-bridge-install-windows-dry-run   # Dry-run Windows install"
	@echo "  just ssh-bridge-install-wsl               # Install WSL bridge block + helper"
	@echo "  just ssh-bridge-install-wsl-dry-run       # Dry-run WSL bridge install"
	@echo "  just ssh-bridge-remediate-windows         # Elevate + fix Windows agent & manifest"
	@echo "  just ssh-bridge-remediate-wsl             # Install socat + re-run WSL installer"
	@echo "  just ssh-bridge-manifest-path             # Print detected Windows + WSL manifest path"
	@echo "  just ssh-bridge-manifest-cat              # Show manifest JSON"
	@echo "  just ssh-bridge-preflight-args --flags    # Run preflight with custom flags (e.g. --strict)"
	@echo "  just ssh-bridge-sync                      # One-shot: Windows install → WSL install → preflight"
	@echo "  just ssh-bridge-uninstall                 # Remove bridge and helper"
	@echo "  just ssh-bridge-status                    # Summarize bridge + deploy status"
	@echo "  just ssh-bridge-fix-config                # Normalize ~/.ssh/config on WSL"
	@echo "  just ssh-bridge-fix-config-dry-run        # Dry-run config fixes"
	@echo "  just ssh-bridge-fix-config-no-acl         # Fix config without touching ACLs"
	@echo "  just ssh-bridge-fix-perms                 # Normalize ~/.ssh perms quickly"
	@echo "  just ssh-bridge-list-hosts                # Show hosts from ~/.ssh/config"
	@echo "  just ssh-bridge-deploy                    # Push key to hosts, verify, cleanup"
	@echo "  just ssh-bridge-deploy-dry-run            # Dry-run deploy"
	@echo "  just ssh-bridge-lan-bootstrap             # Bootstrap LAN hosts from hosts.txt"
	@echo "  just ssh-bridge-lan-bootstrap-dry-run     # Dry-run LAN bootstrap"
	@echo "  just ssh-bridge-cleanup-old-keys DIR=/path # Remove old pubkeys on hosts"
	@echo "  just ssh-bridge-rotate-deploy             # Rotate Windows key then deploy"

# --- Checks & installers ---
ssh-bridge-preflight:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/preflight.sh'

ssh-bridge-preflight-strict:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/preflight.sh --strict'

ssh-bridge-preflight-json:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "{}"; exit 0; fi; bash ssh-agent-bridge/preflight.sh --json'

ssh-bridge-preflight-args *ARGS:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ Must run inside WSL"; exit 1; fi; echo "▶ preflight: {{ARGS}}"; bash ssh-agent-bridge/preflight.sh {{ARGS}}'

ssh-bridge-install-windows:
	@bash -lc 'set -e; if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (run inside WSL)"; exit 1; fi; if [[ ! -f "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1" ]]; then echo "❌ Missing ssh-agent-bridge/install-win-ssh-agent.ps1"; exit 1; fi; WIN_PATH=$(wslpath -w "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1"); echo "🪟 Installing Windows ssh-agent + manifest..."; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" -Verbose'

ssh-bridge-install-windows-dry-run:
	@bash -lc 'set -e; if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (run inside WSL)"; exit 1; fi; if [[ ! -f "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1" ]]; then echo "❌ Missing ssh-agent-bridge/install-win-ssh-agent.ps1"; exit 1; fi; WIN_PATH=$(wslpath -w "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1"); echo "🧪 Dry-run: Windows ssh-agent install..."; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" -DryRun -Verbose || true'

ssh-bridge-remediate-windows:
	@bash -lc 'set -e; if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (run inside WSL)"; exit 1; fi; SCRIPT="$PWD/ssh-agent-bridge/remediate-windows-agent.ps1"; if [[ ! -f "$SCRIPT" ]]; then echo "❌ Missing $SCRIPT"; exit 1; fi; WIN_PATH=$(wslpath -w "$SCRIPT"); echo "🛠  Remediating Windows ssh-agent (will prompt for elevation)..."; powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" | tr -d "\r"'

ssh-bridge-remediate-wsl:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; if ! command -v socat >/dev/null 2>&1; then echo "📦 Installing socat (required for bridge)..."; sudo apt-get update -y >/dev/null 2>&1 || true; sudo apt-get install -y socat; else echo "✅ socat already installed"; fi; echo "🔁 Re-running WSL bridge installer"; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --verbose; echo "✅ Remediation complete; run: ssh-add -l"'

ssh-bridge-sync:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ Run inside WSL"; exit 1; fi; echo "🪟 Step 1: Windows agent + manifest (auto-elevate)"; if command -v powershell.exe >/dev/null 2>&1; then WIN_PS=$(wslpath -w "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1"); powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PS" -Verbose || true; else echo "⚠️ powershell.exe not available; skipping Windows install"; fi; echo "🐧 Step 2: WSL bridge install"; set +e; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --verbose; rc=$?; set -e; if (( rc != 0 )); then echo "❌ WSL install failed (rc=$rc)"; last=$(ls -1t ~/.ssh/logs/wsl-agent-bridge_*.log 2>/dev/null | head -n1 || true); if [[ -f "$last" ]]; then echo "--- Last WSL bridge log (head) ---"; sed -n '1,120p' "$last"; echo "--- Tail ---"; tail -n 40 "$last"; fi; echo "💡 Run: just ssh-bridge-preflight-args --verbose"; exit $rc; fi; echo "🔍 Step 3: Preflight strict"; just ssh-bridge-preflight-args --strict || true; echo "🔑 ssh-add -l:"; ssh-add -l || true; echo "✅ Sync complete"'

ssh-bridge-manifest-path:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  Run inside WSL for path translation"; fi; WINUSER=$(powershell.exe -NoProfile -Command "[Environment]::UserName" 2>/dev/null | tr -d "\r" || true); if [[ -z "$WINUSER" ]]; then echo "❌ Could not resolve Windows user via powershell.exe"; exit 1; fi; WINPATH="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"; echo "Windows user: $WINUSER"; echo "Manifest path (WSL view): $WINPATH"; if [[ -f "$WINPATH" ]]; then echo "✅ Found manifest"; else echo "❌ Manifest not found"; fi'

ssh-bridge-manifest-cat:
	@bash -lc 'set -euo pipefail; WINUSER=$(powershell.exe -NoProfile -Command "[Environment]::UserName" 2>/dev/null | tr -d "\r" || true); [[ -z "$WINUSER" ]] && { echo "❌ Cannot determine Windows user"; exit 1; }; PATH_WSL="/mnt/c/Users/$WINUSER/.ssh/bridge-manifest.json"; if [[ ! -f "$PATH_WSL" ]]; then echo "❌ Manifest missing: $PATH_WSL"; exit 2; fi; sed -n "1,160p" "$PATH_WSL"'

ssh-bridge-install-wsl:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🐧 Installing WSL bridge..."; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --verbose'

ssh-bridge-install-wsl-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧪 Dry-run: WSL bridge install..."; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --dry-run --verbose || true'

ssh-bridge-uninstall:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧹 Uninstalling WSL bridge..."; bash ssh-agent-bridge/uninstall-wsl-bridge.sh'

ssh-bridge-status:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This should be run inside WSL for full accuracy"; fi; bash ssh-agent-bridge/status.sh'

# --- WSL config & perms helpers ---
ssh-bridge-fix-config:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/fix-wsl-ssh-config.sh'

ssh-bridge-fix-config-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/fix-wsl-ssh-config.sh --dry-run'

ssh-bridge-fix-config-no-acl:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/fix-wsl-ssh-config.sh --no-acl'

ssh-bridge-fix-perms:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; bash ssh-agent-bridge/fix-perms-and-clean-wsl-ssh.sh'

ssh-bridge-list-hosts:
	@bash -c 'set -e; bash ssh-agent-bridge/list-hosts.sh'

# Verify npiperelay resolution from manifest and show details
ssh-bridge-verify-npiperelay:
	@bash -lc 'set -euo pipefail; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "ℹ️  Run inside WSL for path translation"; fi; MANI="$(bash -lc "source ssh-agent-bridge/common.sh; ssh_bridge_manifest_path" 2>/dev/null || true)"; if [[ -z "$MANI" ]]; then echo "❌ Manifest not found"; exit 1; fi; bash -lc "source ssh-agent-bridge/common.sh; require_jq || exit 2; p=\$(resolve_npiperelay_from_manifest '$MANI'); echo Resolved: \$p; ls -l \"\$p\""'

# --- Deployment workflows ---
ssh-bridge-deploy:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🚀 Deploying key to hosts (see ~/.ssh/logs)..."; bash ssh-agent-bridge/deploy-ssh-key-to-hosts.sh --verbose'

ssh-bridge-deploy-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧪 Dry-run: deploy to hosts..."; bash ssh-agent-bridge/deploy-ssh-key-to-hosts.sh --dry-run --verbose || true'

# Deploy with explicit parameters (safe defaults). Quote values with spaces.
ssh-bridge-deploy-custom only="" exclude="" jobs="4" timeout="8" resume="0" old_keys_dir="" dry_run="0" verbose="1":
	@bash -c 'set -euo pipefail; [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ This must be run inside WSL"; exit 1; }; args=(); [[ "{{dry_run}}" == "1" ]] && args+=(--dry-run); [[ "{{verbose}}" ]] && args+=(--verbose); [[ -n "{{only}}" ]] && args+=(--only "{{only}}"); [[ -n "{{exclude}}" ]] && args+=(--exclude "{{exclude}}"); [[ -n "{{jobs}}" ]] && args+=(--jobs "{{jobs}}"); [[ -n "{{timeout}}" ]] && args+=(--timeout "{{timeout}}"); [[ "{{resume}}" == "1" ]] && args+=(--resume); [[ -n "{{old_keys_dir}}" ]] && args+=(--old-keys-dir "{{old_keys_dir}}"); echo "🚀 Deploying with args: ${args[*]}"; if [[ "{{dry_run}}" == "1" ]]; then bash ssh-agent-bridge/deploy-ssh-key-to-hosts.sh "${args[@]}" || true; else exec bash ssh-agent-bridge/deploy-ssh-key-to-hosts.sh "${args[@]}"; fi'

# Deploy with raw passthrough flags
ssh-bridge-deploy-args *ARGS:
	@bash -c 'set -e; [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ Run inside WSL"; exit 1; }; echo "🚀 Deploy (passthrough): {{ARGS}}"; bash ssh-agent-bridge/deploy-ssh-key-to-hosts.sh {{ARGS}}'

# Bootstrap hosts listed in ssh-agent-bridge/hosts.txt for initial trust
ssh-bridge-lan-bootstrap:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🌐 LAN bootstrap from hosts.txt..."; bash ssh-agent-bridge/lan-bootstrap.sh --verbose'

ssh-bridge-lan-bootstrap-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧪 Dry-run: LAN bootstrap..."; bash ssh-agent-bridge/lan-bootstrap.sh --dry-run --verbose || true'

# LAN bootstrap with explicit parameters
ssh-bridge-lan-bootstrap-custom hosts="" pubkey="" only="" exclude="" jobs="4" timeout="8" resume="0" disable_pw_auth="0" dry_run="0" verbose="1":
	@bash -lc 'set -euo pipefail; [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ This must be run inside WSL"; exit 1; }; args=(); [[ "{{dry_run}}" == "1" ]] && args+=(--dry-run); [[ "{{verbose}}" ]] && args+=(--verbose); [[ -n "{{hosts}}" ]] && args+=(--hosts "{{hosts}}"); [[ -n "{{pubkey}}" ]] && args+=(--pubkey "{{pubkey}}"); [[ -n "{{only}}" ]] && args+=(--only "{{only}}"); [[ -n "{{exclude}}" ]] && args+=(--exclude "{{exclude}}"); [[ -n "{{jobs}}" ]] && args+=(--jobs "{{jobs}}"); [[ -n "{{timeout}}" ]] && args+=(--timeout "{{timeout}}"); [[ "{{resume}}" == "1" ]] && args+=(--resume); if [[ "{{disable_pw_auth}}" == "1" ]]; then f1="--disable-pass"; f2="word-auth"; args+=("${f1}${f2}"); fi; echo "🌐 LAN bootstrap with args: ${args[*]}"; if [[ "{{dry_run}}" == "1" ]]; then bash ssh-agent-bridge/lan-bootstrap.sh "${args[@]}" || true; else exec bash ssh-agent-bridge/lan-bootstrap.sh "${args[@]}"; fi'

# LAN bootstrap with raw passthrough flags
ssh-bridge-lan-bootstrap-args *ARGS:
	@bash -c 'set -e; [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ Run inside WSL"; exit 1; }; echo "🌐 LAN bootstrap (passthrough): {{ARGS}}"; bash ssh-agent-bridge/lan-bootstrap.sh {{ARGS}}'

# Remove old public keys from hosts after verification; requires DIR env var
ssh-bridge-cleanup-old-keys DIR:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; if [[ -z "${DIR:-}" ]]; then echo "Usage: just ssh-bridge-cleanup-old-keys DIR=/path/to/backup"; exit 2; fi; echo "🧼 Cleaning old keys from hosts..."; bash ssh-agent-bridge/cleanup-old-keys.sh --old-keys-dir "${DIR}"'

# Rotate Windows key then (optionally) install bridge and deploy to hosts
ssh-bridge-rotate-deploy:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; SCRIPT="$PWD/ssh-agent-bridge/full-rotate-and-deploy.sh"; if [[ ! -f "$SCRIPT" ]]; then echo "❌ Missing $SCRIPT"; exit 2; fi; echo "🔄 Rotating key in Windows, then deploying..."; bash "$SCRIPT" --verbose'

ssh-bridge-rotate-deploy-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; SCRIPT="$PWD/ssh-agent-bridge/full-rotate-and-deploy.sh"; if [[ ! -f "$SCRIPT" ]]; then echo "❌ Missing $SCRIPT"; exit 2; fi; echo "🧪 Dry-run: rotate key in Windows, then simulate deploy..."; bash "$SCRIPT" --dry-run --verbose || true'

# Rotate+deploy with raw passthrough flags (e.g. --dry-run, --skip-bridge, --only)
ssh-bridge-rotate-deploy-args *ARGS:
	@bash -c 'set -e; [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ Run inside WSL"; exit 1; }; SCRIPT="$PWD/ssh-agent-bridge/full-rotate-and-deploy.sh"; if [[ ! -f "$SCRIPT" ]]; then echo "❌ Missing $SCRIPT"; exit 2; fi; echo "🔄 Rotate+deploy (passthrough): {{ARGS}}"; bash "$SCRIPT" {{ARGS}}'

# ============================================================================
# Chezmoi helpers for Windows (run from WSL)
# ============================================================================

windows-chezmoi-diff:
	@bash scripts/windows-chezmoi-diff.sh || true

windows-chezmoi-apply:
	@bash scripts/windows-chezmoi-apply.sh || true

# Preview then apply Windows-side chezmoi changes (convenience alias)
# Usage: `just windows-chezmoi-diff-apply` (run from WSL)
windows-chezmoi-diff-apply:
	@just windows-chezmoi-diff
	@just windows-chezmoi-apply

# Interactive apply (prompts enabled, no pager)
windows-chezmoi-apply-interactive:
	@bash scripts/windows-chezmoi-apply-interactive.sh

# ============================================================================
# Chezmoi diagnostics & remediation (Linux/WSL side)
# ============================================================================

# Show chezmoi status: version, sourceDir, managed count.
chezmoi-status:
		@bash -lc 'set -euo pipefail; \
		  if ! command -v chezmoi >/dev/null 2>&1; then echo "❌ chezmoi not on PATH"; exit 1; fi; \
		  CHZ_VER=$(chezmoi --version); \
		  echo "🔍 Chezmoi version: $CHZ_VER"; \
		  if [[ -n "${CHEZMOI_SOURCE_DIR:-}" ]]; then echo "⚠️  CHEZMOI_SOURCE_DIR is set: $CHEZMOI_SOURCE_DIR (overrides config)"; fi; \
		  SRC_JSON=$(chezmoi data 2>/dev/null | jq -r ".chezmoi.sourceDir? // \"\"" 2>/dev/null || echo ""); \
		  if [[ -z "$SRC_JSON" || "$SRC_JSON" == "null" ]]; then \
		    echo "⚠️  sourceDir not resolved via template data (config may not have sourceDir)"; \
		    SRC=$(chezmoi source-path 2>/dev/null || true); \
		  else SRC="$SRC_JSON"; fi; \
		  echo "📂 sourceDir: $SRC"; \
		  if [[ -n "$SRC" && -f "$SRC/.chezmoiignore" ]]; then \
		    if rg -n "^!dot_\\*" "$SRC/.chezmoiignore" >/dev/null 2>&1; then \
		      echo "⚠️  Invalid pattern in $SRC/.chezmoiignore: !dot_* (patterns match destination paths)."; \
		      echo "   Fix with: just chezmoi-fix-ignore"; \
		    fi; \
		  fi; \
			COUNT=$(chezmoi managed 2>/dev/null | wc -l | tr -d " "); \
			echo "📊 managed entries: $COUNT"; \
			if [[ "$COUNT" -eq 0 ]]; then echo "⚠️  No managed entries detected (run: just chezmoi-init-if-empty)"; fi; \
		  echo "📝 doctor (source-dir line):"; CHEZMOI_NO_PAGER=1 chezmoi doctor | grep -E "config-file|source-dir|working-tree" || true'

# List first 40 managed entries (safe even if empty)
chezmoi-managed:
    @bash -lc 'set -euo pipefail; CHEZMOI_NO_PAGER=1 chezmoi managed 2>/dev/null | head -40 || true'

# Show diff (no pager). Warn if state empty.
chezmoi-diff:
	@bash -lc 'set -euo pipefail; \
	  SRC=$(chezmoi data 2>/dev/null | jq -r ".chezmoi.sourceDir? // \"\"" 2>/dev/null || echo ""); \
	  if [[ -n "$SRC" && -f "$SRC/.chezmoiignore" ]] && rg -n "^!dot_\\*" "$SRC/.chezmoiignore" >/dev/null 2>&1; then \
	    echo "❌ Invalid ignore pattern detected in $SRC/.chezmoiignore: !dot_*"; \
	    echo "   Fix it with: just chezmoi-fix-ignore"; \
	    exit 2; \
	  fi; \
	  COUNT=$(chezmoi managed 2>/dev/null | wc -l | tr -d " "); \
	  if [[ "$COUNT" -eq 0 ]]; then echo "⚠️  No source entries – diff meaningless. Run: just chezmoi-status"; exit 0; fi; \
	  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff || true'

# Reconfigure sourceDir to this repo & ensure minimal whitelist ignore (backs up existing files)
chezmoi-fix-source:
	@bash -lc 'set -euo pipefail; ROOT="$PWD"; CFG=~/.config/chezmoi/chezmoi.toml; mkdir -p "$(dirname "$CFG")"; if [[ -f "$CFG" ]]; then cp "$CFG" "$CFG.bak.$(date +%s)"; echo "🗂  Backed up config to $CFG.bak.*"; fi; printf "sourceDir = \"%s\"\n" "$ROOT" > "$CFG"; echo "✅ Wrote sourceDir to $CFG"; IGN=".chezmoiignore"; if [[ -f "$IGN" ]]; then cp "$IGN" "$IGN.bak.$(date +%s)"; echo "🗂  Backed up $IGN"; fi; { echo "# Minimal whitelist for destination paths"; echo "*"; echo "!.chezmoiignore"; echo "!.*"; echo "!.*/**"; } > "$IGN"; if rg -n "^!dot_\*" "$IGN" >/dev/null 2>&1; then echo "❌ Refusing to write invalid pattern !dot_* to $IGN"; exit 2; fi; echo "✅ Wrote destination-based whitelist $IGN"; echo "🔁 Re-checking..."; just chezmoi-status'

# Replace .chezmoiignore with minimal whitelist (backup prior)
chezmoi-minimal-ignore:
		@bash -lc 'set -euo pipefail; IGN=".chezmoiignore"; [[ -f "$IGN" ]] && cp "$IGN" "$IGN.bak.$(date +%s)" && echo "🗂  Backed up $IGN"; { echo "# Minimal whitelist for destination paths"; echo "*"; echo "!.chezmoiignore"; echo "!.*"; echo "!.*/**"; } > "$IGN"; if rg -n "^!dot_\*" "$IGN" >/dev/null 2>&1; then echo "❌ Invalid pattern written to $IGN"; exit 2; fi; echo "✅ Installed destination-based whitelist $IGN";'

# Self-test chezmoi in an isolated temp source to diagnose scanning issues
chezmoi-selftest:
	@bash -lc 'set -euo pipefail; tmp=$(mktemp -d); pushd "$tmp" >/dev/null; printf "*\n!.chezmoiignore\n!.probe_file\n" > .chezmoiignore; echo "HELLO" > dot_probe_file; CHEZMOI_NO_PAGER=1 chezmoi -S "$tmp" managed | head || true; COUNT=$(chezmoi -S "$tmp" managed | wc -l | tr -d " "); echo "🧪 Temp managed count: $COUNT (expected >=1)"; popd >/dev/null; rm -rf "$tmp"'

# Show raw chezmoi template metadata (useful for debugging)
chezmoi-meta:
    @bash -lc 'set -euo pipefail; chezmoi data | jq ".chezmoi"'

# Reinstall chezmoi (Linux/WSL) preserving backup. For Windows, use choco upgrade chezmoi.
chezmoi-reinstall:
	@bash -lc 'set -euo pipefail; if ! command -v curl >/dev/null 2>&1; then echo "❌ curl required"; exit 1; fi; \
	  if command -v chezmoi >/dev/null 2>&1; then OLD=$(command -v chezmoi); cp "$OLD" "$OLD.bak.$(date +%s)"; echo "🗂  Backed up existing binary"; fi; \
	  echo "⬇️  Downloading latest chezmoi..."; sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin >/dev/null; \
	  echo "✅ Installed: $(chezmoi --version)"; [[ -n "${WSL_DISTRO_NAME:-}" ]] && echo "💡 Windows upgrade via: choco upgrade chezmoi -y" || true'

# Update (alias) – for Linux/WSL (Windows users: choco upgrade chezmoi)
chezmoi-upgrade: chezmoi-reinstall

# Initialize or repair chezmoi state if empty (guard)
chezmoi-init-if-empty:
	@bash -lc 'set -euo pipefail; if ! command -v chezmoi >/dev/null 2>&1; then echo "❌ chezmoi not installed"; exit 1; fi; COUNT=$(chezmoi managed 2>/dev/null | wc -l | tr -d " "); if [[ "$COUNT" -gt 0 ]]; then echo "✅ Already have managed entries ($COUNT)"; exit 0; fi; echo "🛠  State empty – initializing..."; just chezmoi-fix-source >/dev/null 2>&1 || true; just chezmoi-fix-ignore >/dev/null 2>&1 || true; ORIGIN=$(git config --get remote.origin.url 2>/dev/null || true); TMPCOUNT=$(chezmoi managed 2>/dev/null | wc -l | tr -d " "); if [[ "$TMPCOUNT" -eq 0 && -n "$ORIGIN" ]]; then echo "🌐 Attempting re-init from origin: $ORIGIN"; rm -rf ~/.local/share/chezmoi; CHEZMOI_NO_PAGER=1 chezmoi init --apply "$ORIGIN" || true; just chezmoi-fix-ignore >/dev/null 2>&1 || true; fi; NEWCOUNT=$(chezmoi managed 2>/dev/null | wc -l | tr -d " "); if [[ "$NEWCOUNT" -eq 0 ]]; then echo "❌ Still empty. Use: just chezmoi-reinit-from-origin OR just chezmoi-reinit REPO=..."; exit 2; fi; echo "✅ Populated managed entries ($NEWCOUNT)."'

# Auto-populate then show status (convenience)
chezmoi-autopopulate:
	@bash -lc 'set -euo pipefail; just chezmoi-init-if-empty; just chezmoi-status'

# Reinitialize chezmoi source from current repo origin (destructive to existing default source)
chezmoi-reinit-from-origin:
	@bash -lc 'set -euo pipefail; ORIGIN=$(git config --get remote.origin.url 2>/dev/null || true); \
	  if [[ -z "$ORIGIN" ]]; then echo "❌ No git origin detected. Use: just chezmoi-reinit REPO=..."; exit 2; fi; \
	  echo "🌐 Reinitializing from $ORIGIN"; \
	  backup=~/.local/share/chezmoi.backup.$(date +%s); [[ -d ~/.local/share/chezmoi ]] && mv ~/.local/share/chezmoi "$backup" && echo "🗂  Previous source backed up to $backup"; \
	  CHEZMOI_NO_PAGER=1 chezmoi init --apply "$ORIGIN" || { echo "❌ init failed"; exit 3; }; \
	  just chezmoi-fix-ignore >/dev/null 2>&1 || true; \
	  just chezmoi-status'

# Reinitialize from specified repository URL
chezmoi-reinit REPO:
	@bash -lc 'set -euo pipefail; REPO="{{REPO}}"; if [[ -z "$REPO" ]]; then echo "Usage: just chezmoi-reinit REPO=https://..."; exit 2; fi; \
	  echo "🌐 Reinitializing from $REPO"; backup=~/.local/share/chezmoi.backup.$(date +%s); \
	  [[ -d ~/.local/share/chezmoi ]] && mv ~/.local/share/chezmoi "$backup" && echo "🗂  Previous source backed up to $backup"; \
	  CHEZMOI_NO_PAGER=1 chezmoi init --apply "$REPO" || { echo "❌ init failed"; exit 3; }; \
	  just chezmoi-fix-ignore >/dev/null 2>&1 || true; \
	  just chezmoi-status'

# Sync dot_* templates from repo working tree to default source (non-destructive overwrite of same names)
chezmoi-sync-to-default:
	@bash -lc 'set -euo pipefail; just chezmoi-sync-templates >/dev/null 2>&1 || true; SRC_REPO="$PWD"; DEST=~/.local/share/chezmoi; mkdir -p "$DEST"; count=0; for f in "$SRC_REPO"/dot_*; do [ -e "$f" ] || continue; cp -f "$f" "$DEST/" && count=$((count+1)); done; echo "⬆️  Copied $count dot_* files to $DEST"; just chezmoi-status'

# Sync from default source back to repo (refuses if repo dirty unless FORCE=1)
chezmoi-sync-from-default:
	@bash -lc 'set -euo pipefail; if [[ "${FORCE:-0}" != "1" && -n "$(git status --porcelain 2>/dev/null)" ]]; then echo "❌ Repo dirty. Commit/stash or run with FORCE=1 just chezmoi-sync-from-default"; exit 2; fi; SRC=~/.local/share/chezmoi; DEST="$PWD"; count=0; for f in "$SRC"/dot_*; do [ -e "$f" ] || continue; cp -f "$f" "$DEST/" && count=$((count+1)); done; echo "⬇️  Copied $count dot_* files to repo";'

# Sync templates directory from repo into default source (~/.local/share/chezmoi/templates)
chezmoi-sync-templates:
	@bash -lc 'set -euo pipefail; SRC_TEMPL="$PWD/templates"; DEST_TEMPL="$HOME/.local/share/chezmoi/templates"; \
	  if [[ ! -d "$SRC_TEMPL" ]]; then echo "ℹ️  No templates/ directory in repo; skipping."; exit 0; fi; \
	  mkdir -p "$DEST_TEMPL"; rsync -a "$SRC_TEMPL/" "$DEST_TEMPL/"; echo "⬆️  Synced templates to $DEST_TEMPL";'

# Show and optionally clear CHEZMOI_SOURCE_DIR (cannot persistently unset for parent shell)
chezmoi-env-check:
	@bash -lc 'if [[ -n "${CHEZMOI_SOURCE_DIR:-}" ]]; then echo "CHEZMOI_SOURCE_DIR=$CHEZMOI_SOURCE_DIR"; else echo "CHEZMOI_SOURCE_DIR not set"; fi;'

# Repair .chezmoiignore in the default sourceDir (newline corruption safeguard)
chezmoi-fix-ignore:
	@bash -lc 'set -euo pipefail; SRC=~/.local/share/chezmoi; [[ -d "$SRC" ]] || { echo "❌ Source dir $SRC missing"; exit 1; }; IGN="$SRC/.chezmoiignore"; TMP="$IGN.new"; { echo "# Autogenerated minimal whitelist for destination paths"; echo "*"; echo "!.chezmoiignore"; echo "!.*"; echo "!.*/**"; } > "$TMP"; if rg -n "^!dot_\*" "$TMP" >/dev/null 2>&1; then echo "❌ Refusing to write invalid pattern !dot_* to $TMP"; rm -f "$TMP"; exit 2; fi; mv "$TMP" "$IGN"; echo "✅ Regenerated destination-based whitelist $IGN"; head -n 20 "$IGN"'

# Validate .chezmoiignore files to prevent wrong source-name patterns.
chezmoi-validate-ignore:
	@bash -lc 'set -euo pipefail; ERR=0; for F in "$PWD/.chezmoiignore" "$HOME/.local/share/chezmoi/.chezmoiignore"; do [[ -f "$F" ]] || continue; if rg -n "^!dot_\\*" "$F" >/dev/null 2>&1; then echo "❌ Invalid pattern in $F: !dot_* (matches source names, not destinations)"; ERR=1; fi; done; exit $ERR'

# Adopt default source as repo: move existing repo aside, move source in, and symlink
chezmoi-adopt-default:
	@bash -lc 'set -euo pipefail; if [[ ! -d ~/.local/share/chezmoi ]]; then echo "❌ Default source missing"; exit 1; fi; if [[ -d "$PWD/.git" ]]; then echo "⚠️  Current directory already a git repo. Aborting."; exit 2; fi; echo "🚚 Moving current directory aside and adopting default source"; backup="$PWD.backup.$(date +%s)"; mv "$PWD" "$backup"; mv ~/.local/share/chezmoi "$PWD"; ln -sfn "$PWD" ~/.local/share/chezmoi; echo "✅ Adopted. Original moved to $backup";'
