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

# Set up projects directory and Windows symlink (WSL2 only)
setup-projects:
	@bash scripts/setup-projects-idempotent.sh

# Set up PowerShell 7 profile for Windows (requires PowerShell 7 installed)
setup-pwsh7:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🪟 Setting up PowerShell 7 profile for Windows..."
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."
        echo "💡 Run from WSL to configure the Windows-side PowerShell profile."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."
        echo "💡 Ensure Windows PowerShell or PowerShell 7 is installed and accessible."
        exit 1
    fi
    bash scripts/setup-pwsh7.sh

setup-pwsh7-dry-run:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🪟(dry-run) Setting up PowerShell 7 profile for Windows..."
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."
        exit 0
    fi
    bash scripts/setup-pwsh7.sh --dry-run

# Force symlink for Windows $PROFILE (fails if symlink can't be created)
setup-pwsh7-symlink:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🪟 Forcing Windows $PROFILE symlink..."
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ Neither powershell.exe nor pwsh.exe is available from WSL."
        exit 1
    fi
    bash scripts/setup-pwsh7.sh --require-symlink

# Windows Developer Mode helpers (run from WSL)
devmode-status:
	@bash -c 'powershell.exe -NoProfile -NonInteractive -Command "try { $v=(Get-ItemProperty -Path ''HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'' -Name ''AllowDevelopmentWithoutDevLicense'' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense; if($v -eq 1){Write-Output ''Developer Mode: Enabled''} elseif($v -eq 0){Write-Output ''Developer Mode: Disabled''} else {Write-Output ''Developer Mode: Unknown''} } catch { Write-Output ''Developer Mode: Unknown'' }" | tr -d "\r"'

devmode-enable:
	@bash -c 'echo "⚠️  Attempting to enable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\SOFTWARE\\\\CurrentVersion\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 1; Write-Host ''''Developer Mode enabled'''' -ForegroundColor Green\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

devmode-disable:
	@bash -c 'echo "⚠️  Attempting to disable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\SOFTWARE\\\\CurrentVersion\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 0; Write-Host ''''Developer Mode disabled'''' -ForegroundColor Yellow\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

# Force symlink via elevated Windows PowerShell (UAC prompt expected)
setup-pwsh7-symlink-admin:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🪟 Forcing Windows $PROFILE symlink via elevated PowerShell (UAC prompt expected)..."
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "❌ powershell.exe not available from WSL."
        exit 1
    fi
    # Build UNC path to this repo under WSL: \\wsl.localhost\<distro>\<path>
    REPO_UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}$(pwd | sed 's|^/|\\|; s|/|\\|g')"
    SCRIPT_UNC="${REPO_UNC}\\scripts\\invoke-elevated-symlink.ps1"
    TARGET_UNC="${REPO_UNC}\\PowerShell\\Microsoft.PowerShell_profile.ps1"
    echo "🔗 Script: ${SCRIPT_UNC}"
    echo "🎯 Target: ${TARGET_UNC}"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${SCRIPT_UNC}" -Target "${TARGET_UNC}"

# Verify Windows PowerShell profile links to this repo and theme resolves
verify-windows-profile:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This verification targets WSL; run from WSL."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ Neither powershell.exe nor pwsh.exe available from WSL."
        exit 1
    fi
    bash scripts/verify-windows-profile.sh

# Verify Oh My Posh theme resolution and binary availability on Windows
verify-windows-theme:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This verification targets WSL; run from WSL."
        exit 0
    fi
    if ! command -v powershell.exe >/dev/null 2>&1 && ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ Neither powershell.exe nor pwsh.exe available from WSL."
        exit 1
    fi
    bash scripts/verify-windows-theme.sh

# List available Oh My Posh themes on Windows
list-windows-themes:
    #!/usr/bin/env bash
    set -euo pipefail
    UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}\\home\\${USER}\\dotfiles"
    powershell.exe -NoProfile -NonInteractive -Command "\
        if (-not \$env:DOTFILES_ROOT -or [string]::IsNullOrWhiteSpace(\$env:DOTFILES_ROOT)) { \$env:DOTFILES_ROOT = '$UNC' } ; \
        \$themes = Get-ChildItem -LiteralPath (Join-Path \$env:DOTFILES_ROOT 'PowerShell\Themes') -Filter *.omp.json -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name ; \
        if (\$themes) { \$themes | ForEach-Object { Write-Host (\" - \" + \$_) } } else { Write-Warning \"No themes found\" }\
    " | tr -d "\r"

# Set OMP_THEME for Windows (persistent) and reinitialize current pwsh if present
# Usage: just set-windows-theme powerlevel10k_modern
set-windows-theme THEME:
    #!/usr/bin/env bash
    set -euo pipefail
    UNC="\\\\wsl.localhost\\${WSL_DISTRO_NAME}\\home\\${USER}\\dotfiles"
    THEME_STR='{{THEME}}'
    powershell.exe -NoProfile -Command "\
        \$t = '$THEME_STR'; if (-not \$t) { Write-Error 'Missing theme name'; exit 1 }; if (\$t -notmatch '\\.omp\\.json$') { \$t = \$t + '.omp.json' }; \
        \$root = \$env:DOTFILES_ROOT; if ([string]::IsNullOrWhiteSpace(\$root)) { \$root = '$UNC' }; \
        \$themePath = Join-Path \$root (Join-Path 'PowerShell\\Themes' \$t); \
        if (-not (Test-Path \$themePath)) { Write-Error ('Theme not found: ' + \$themePath); exit 2 }; \
        try { Set-ItemProperty -Path 'HKCU:\\Environment' -Name 'OMP_THEME' -Value \$t -ErrorAction Stop } catch { }; \
        [Environment]::SetEnvironmentVariable('OMP_THEME', \$t, 'User') | Out-Null; \
        Write-Host ('✅ Set OMP_THEME=' + \$t) -ForegroundColor Green; \
        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { \
            try { oh-my-posh init pwsh --config \$themePath | Invoke-Expression; Write-Host '🎨 Reinitialized prompt for this shell' -ForegroundColor Green } catch { Write-Warning \$_.Exception.Message } \
        } else { Write-Warning 'oh-my-posh not found on PATH' }"

# Complete Windows integration setup (combines multiple setup tasks)
setup-windows-integration:
	@echo "🪟 Setting up complete Windows integration..."
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

# Fix PowerShell 7 profile if it's not working correctly
fix-pwsh7:
	@echo "🔧 Diagnosing and fixing PowerShell 7 profile issues..."
	@just setup-pwsh7

# Clean up old PowerShell profiles that might conflict
clean-old-powershell-profiles:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧹 Cleaning up old PowerShell profiles..."

    # Guard: this recipe is intended for WSL
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "ℹ️  This recipe targets WSL; no WSL detected. Nothing to do."
        echo "💡 Run from WSL if you want to clean Windows-side PowerShell profiles."
        exit 0
    fi

    PWSH7_PROFILE=""
    if command -v pwsh.exe >/dev/null 2>&1; then
        PWSH7_PROFILE=$(pwsh.exe -NoProfile -Command '$PROFILE' 2>/dev/null | tr -d '\r' || true)
    elif command -v powershell.exe >/dev/null 2>&1; then
        PWSH7_PROFILE=$(powershell.exe -NoProfile -Command '$PROFILE' 2>/dev/null | tr -d '\r' || true)
    else
        echo "❌ Neither pwsh.exe nor powershell.exe found on the Windows side."
        echo "💡 Install PowerShell (pwsh) or ensure Windows PowerShell is available."
        exit 0
    fi

    if [[ -n "${PWSH7_PROFILE}" ]]; then
        # Map Windows path (e.g. C:\\Users\\Name\\...) to WSL mount (/mnt/c/Users/Name/...)
        PWSH7_PROFILE_WSL=$(printf "%s" "${PWSH7_PROFILE}" | sed -E -e 's|^([A-Za-z]):\\\\|/mnt/\L\1/|' -e 's|\\\\|/|g')
        if [[ -f "${PWSH7_PROFILE_WSL}" ]]; then
            BACKUP_NAME="${PWSH7_PROFILE_WSL}.backup.$(date +%Y%m%d_%H%M%S)"
            mv "${PWSH7_PROFILE_WSL}" "${BACKUP_NAME}"
            echo "✅ Backed up profile to: ${BACKUP_NAME}"
        else
            echo "ℹ️  No existing PowerShell 7 profile found at ${PWSH7_PROFILE}"
        fi
    else
        echo "❌ Could not determine PowerShell profile path from Windows PowerShell"
        echo '💡 Try launching PowerShell on Windows and check $PROFILE there.'
    fi

    echo "🎉 PowerShell profile cleanup complete!"

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
	#!/usr/bin/env bash
	echo "🌐 Setting up WSL2 for remote access..."
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
		echo "❌ This command must be run from WSL2"
		exit 1
	fi
	./scripts/setup-wsl2-remote-access.sh
	echo ""
	echo "🎉 WSL2 remote access setup complete!"
	echo "💡 Don't forget to run the Windows configuration script as Administrator"

# Configure Windows for WSL2 remote access (run the PowerShell script)
setup-wsl2-remote-windows:
	#!/usr/bin/env bash
	echo "🪟 Configuring Windows for WSL2 remote access..."
	if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
		echo "❌ This command is designed for WSL2 environments"
		exit 1
	fi
	if ! command -v powershell.exe >/dev/null 2>&1; then
		echo "❌ PowerShell not found on Windows"
		exit 1
	fi
	echo "▶️  Running Windows configuration script..."
	echo "⚠️  This requires Administrator privileges on Windows"
	powershell.exe -ExecutionPolicy Bypass -File "$PWD/scripts/setup-wsl2-remote-windows.ps1"
	echo ""
	echo "🎉 Windows WSL2 remote configuration complete!"

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
	@echo "  just ssh-bridge-uninstall                 # Remove bridge and helper"
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

ssh-bridge-install-windows:
    #!/usr/bin/env bash
    set -e
    if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (run inside WSL)"; exit 1; fi
    if [[ ! -f "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1" ]]; then echo "❌ Missing ssh-agent-bridge/install-win-ssh-agent.ps1"; exit 1; fi
    WIN_PATH=$(wslpath -w "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1")
    echo "🪟 Installing Windows ssh-agent + manifest..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" -Verbose

ssh-bridge-install-windows-dry-run:
    #!/usr/bin/env bash
    set -e
    if ! command -v powershell.exe >/dev/null 2>&1; then echo "❌ powershell.exe not found (run inside WSL)"; exit 1; fi
    if [[ ! -f "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1" ]]; then echo "❌ Missing ssh-agent-bridge/install-win-ssh-agent.ps1"; exit 1; fi
    WIN_PATH=$(wslpath -w "$PWD/ssh-agent-bridge/install-win-ssh-agent.ps1")
    echo "🧪 Dry-run: Windows ssh-agent install..."
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$WIN_PATH" -DryRun -Verbose || true

ssh-bridge-install-wsl:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🐧 Installing WSL bridge..."; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --verbose'

ssh-bridge-install-wsl-dry-run:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧪 Dry-run: WSL bridge install..."; bash ssh-agent-bridge/install-wsl-agent-bridge.sh --dry-run --verbose || true'

ssh-bridge-uninstall:
	@bash -c 'set -e; if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then echo "❌ This must be run inside WSL"; exit 1; fi; echo "🧹 Uninstalling WSL bridge..."; bash ssh-agent-bridge/uninstall-wsl-bridge.sh'

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
    #!/usr/bin/env bash
    set -euo pipefail
    [[ -z "${WSL_DISTRO_NAME:-}" ]] && { echo "❌ This must be run inside WSL"; exit 1; }
    args=()
    [[ "{{dry_run}}" == "1" ]] && args+=(--dry-run)
    [[ "{{verbose}}" ]] && args+=(--verbose)
    [[ -n "{{hosts}}" ]] && args+=(--hosts "{{hosts}}")
    [[ -n "{{pubkey}}" ]] && args+=(--pubkey "{{pubkey}}")
    [[ -n "{{only}}" ]] && args+=(--only "{{only}}")
    [[ -n "{{exclude}}" ]] && args+=(--exclude "{{exclude}}")
    [[ -n "{{jobs}}" ]] && args+=(--jobs "{{jobs}}")
    [[ -n "{{timeout}}" ]] && args+=(--timeout "{{timeout}}")
    [[ "{{resume}}" == "1" ]] && args+=(--resume)
    [[ "{{disable_pw_auth}}" == "1" ]] && args+=(--disable-password-auth)
    echo "🌐 LAN bootstrap with args: ${args[*]}"
    if [[ "{{dry_run}}" == "1" ]]; then
        bash ssh-agent-bridge/lan-bootstrap.sh "${args[@]}" || true
    else
        exec bash ssh-agent-bridge/lan-bootstrap.sh "${args[@]}"
    fi

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

windows-chezmoi-diff SRC="${PWD}":
	@bash scripts/windows-chezmoi-diff.sh "{{SRC}}"

windows-chezmoi-apply SRC="${PWD}":
	@bash scripts/windows-chezmoi-apply.sh "{{SRC}}"
