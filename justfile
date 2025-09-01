# Justfile for dotfiles project

# Display a list of available tasks when no target is specified.
default:
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
    @bash scripts/setup-pwsh7.sh

setup-pwsh7-dry-run:
    @bash scripts/setup-pwsh7.sh --dry-run

# Force symlink for Windows $PROFILE (fails if symlink can't be created)
setup-pwsh7-symlink:
    @bash scripts/setup-pwsh7.sh --require-symlink

# Windows Developer Mode helpers (run from WSL)
devmode-status:
    @bash -c 'powershell.exe -NoProfile -NonInteractive -Command "try { $v=(Get-ItemProperty -Path ''HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\AppModelUnlock'' -Name ''AllowDevelopmentWithoutDevLicense'' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense; if($v -eq 1){Write-Output ''Developer Mode: Enabled''} elseif($v -eq 0){Write-Output ''Developer Mode: Disabled''} else {Write-Output ''Developer Mode: Unknown''} } catch { Write-Output ''Developer Mode: Unknown'' }" | tr -d "\r"'

devmode-enable:
    @bash -c 'echo "⚠️  Attempting to enable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\\\SOFTWARE\\\\\\CurrentVersion\\\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 1; Write-Host ''''Developer Mode enabled'''' -ForegroundColor Green\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

devmode-disable:
    @bash -c 'echo "⚠️  Attempting to disable Windows Developer Mode (requires admin)."; powershell.exe -NoProfile -Command "try { Start-Process PowerShell -Verb RunAs -ArgumentList ''-NoProfile -Command \"Set-ItemProperty -Path ''''HKLM:\\\\\\SOFTWARE\\\\\\CurrentVersion\\\\\\AppModelUnlock'''' -Name AllowDevelopmentWithoutDevLicense -Value 0; Write-Host ''''Developer Mode disabled'''' -ForegroundColor Yellow\"'' } catch { Write-Warning ''Failed to launch elevated PowerShell'' }"'

# Force symlink via elevated Windows PowerShell (UAC prompt expected)
setup-pwsh7-symlink-admin:
    @bash -c 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "\\wsl.localhost\\Ubuntu-24.04\\home\\sprime01\\dotfiles\\scripts\\invoke-elevated-symlink.ps1" -Target "\\wsl.localhost\\Ubuntu-24.04\\home\\sprime01\\dotfiles\\PowerShell\\Microsoft.PowerShell_profile.ps1"'

# Verify Windows PowerShell profile links to this repo and theme resolves
verify-windows-profile:
    @bash scripts/verify-windows-profile.sh

# Verify Oh My Posh theme resolution and binary availability on Windows
verify-windows-theme:
    @bash scripts/verify-windows-theme.sh

# List available Oh My Posh themes on Windows
list-windows-themes:
    @bash -c 'powershell.exe -NoProfile -NonInteractive -Command "\
        $themes = Get-ChildItem -LiteralPath (Join-Path $env:DOTFILES_ROOT ''PowerShell\Themes'') -Filter *.omp.json -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name; \
        if ($themes) { $themes | ForEach-Object { Write-Host \" - \$_\" } } else { Write-Warning \"No themes found\" }\
    " | tr -d "\r"'

# Set OMP_THEME for Windows (persistent) and reinitialize current pwsh if present
# Usage: just set-windows-theme powerlevel10k_modern
set-windows-theme THEME:
    @bash -c 'powershell.exe -NoProfile -Command "param([string]\$t); if (-not \$t) { Write-Error \"Missing theme name\"; exit 1 }; if (\$t -notmatch \"\\.omp\\.json$\") { \$t = \$t + \".omp.json\" }; $root = $env:DOTFILES_ROOT; if ([string]::IsNullOrWhiteSpace($root)) { $root = \"\\\\wsl.localhost\\\\Ubuntu-24.04\\\\home\\\\sprime01\\\\dotfiles\" }; $themePath = Join-Path $root (Join-Path \"PowerShell\\Themes\" \$t); if (-not (Test-Path $themePath)) { Write-Error (\"Theme not found: \" + $themePath); exit 2 }; try { Set-ItemProperty -Path \"HKCU:\\Environment\" -Name \"OMP_THEME\" -Value \$t -ErrorAction Stop } catch { }; [Environment]::SetEnvironmentVariable(\"OMP_THEME\", \$t, \"User\") | Out-Null; Write-Host (\"✅ Set OMP_THEME=\" + \$t) -ForegroundColor Green; if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { try { oh-my-posh init pwsh --config $themePath | Invoke-Expression; Write-Host \"🎨 Reinitialized prompt for this shell\" -ForegroundColor Green } catch { Write-Warning \$_.Exception.Message } } else { Write-Warning \"oh-my-posh not found on PATH\" }" -- '{{THEME}}'

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
    @bash -c 'echo "🧹 Cleaning up old PowerShell profiles..."; PWSH7_PROFILE=$$(pwsh.exe -NoProfile -Command \''$PROFILE'\' 2>/dev/null | tr -d "\r" 2>/dev/null); if [[ -n "$$PWSH7_PROFILE" ]]; then PWSH7_PROFILE_WSL=$$(echo "$$PWSH7_PROFILE" | sed "s|^C:\\|/mnt/c/|; s|\\\\|/|g"); if [[ -f "$$PWSH7_PROFILE_WSL" ]]; then BACKUP_NAME="$$PWSH7_PROFILE_WSL.backup.$$(date +%Y%m%d_%H%M%S)"; mv "$$PWSH7_PROFILE_WSL" "$$BACKUP_NAME"; echo "✅ Backed up profile to: $$BACKUP_NAME"; else echo "ℹ️  No existing PowerShell 7 profile found at $$PWSH7_PROFILE"; fi; else echo "❌ Could not determine PowerShell 7 profile path"; fi; echo "🎉 PowerShell profile cleanup complete!"'

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
