# Justfile for dotfiles project

# Display a list of available tasks when no target is specified.
default:
    @just --list

# Run all automated tests (shell + PowerShell if available). Fast validation before commits.
    @bash scripts/run-tests.sh

<<<<<<< HEAD
# Lint shell scripts (shellcheck) and verify formatting (shfmt diff mode)
lint:
    @bash tools/lint.sh

# Auto-format shell scripts in-place using shfmt
format:
    @shfmt -w .

# CI-parity: run the comprehensive test suite mirroring GitHub Actions workflow
    # Install direnv across supported platforms (idempotent)

# Interactive state-aware setup wizard (Unix shells)
=======
# Install direnv across supported platforms (idempotent)
install-direnv:
    @bash -c 'set -euo pipefail; echo "🌱 Installing direnv..."; if command -v direnv >/dev/null 2>&1; then echo "✅ direnv already installed: $$(command -v direnv)"; direnv version || true; exit 0; fi; OS=$$(uname -s); if command -v apt >/dev/null 2>&1; then echo "📦 Using apt"; sudo apt update -y >/dev/null 2>&1 || true; sudo apt install -y direnv; elif command -v brew >/dev/null 2>&1; then echo "🍺 Using Homebrew"; brew install direnv; elif command -v dnf >/dev/null 2>&1; then echo "📦 Using dnf"; sudo dnf install -y direnv; elif command -v pacman >/dev/null 2>&1; then echo "📦 Using pacman"; sudo pacman -Sy --noconfirm direnv; elif command -v zypper >/dev/null 2>&1; then echo "📦 Using zypper"; sudo zypper install -y direnv; elif command -v scoop >/dev/null 2>&1; then echo "🪟 Using scoop (Windows)"; scoop install direnv; elif command -v choco >/dev/null 2>&1; then echo "🪟 Using choco (Windows)"; choco install direnv -y; else echo "❌ No supported package manager found. Install manually from https://direnv.net"; exit 1; fi; if command -v direnv >/dev/null 2>&1; then echo "🎉 direnv installed: $$(direnv version)"; echo "💡 Create a .envrc in a project and run: direnv allow"; echo "💡 To disable temporarily: export DISABLE_DIRENV=1"; else echo "❌ direnv installation appears to have failed"; exit 1; fi'

# Test direnv integration in an isolated temp directory
    # Interactive state-aware setup wizard (Unix shells)
# Launch the interactive setup wizard for Unix shells.  This script
<<<<<<< HEAD
# guides you through configuring shells, installing optional components
# like VS Code settings, and enabling MCP/SSH integration.
>>>>>>> 550e43d (feat: Add direnv integration for Bash, Zsh, and PowerShell with installation and testing support)
=======
# guides you through configuring shells and installing optional components
# like VS Code settings.
>>>>>>> 8336c85 (Refactor dotfiles configuration and remove SSH agent bridge)
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

# Fix PowerShell 7 profile if it's not working correctly
fix-pwsh7:
    @echo "🔧 Diagnosing and fixing PowerShell 7 profile issues..."
    @just setup-pwsh7

# Clean up old PowerShell profiles that might conflict
clean-old-powershell-profiles:
    @bash -c 'echo "🧹 Cleaning up old PowerShell profiles..."; WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null); OLD_PROFILE="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Microsoft.PowerShell_profile.ps1"; if [[ -f "$OLD_PROFILE" ]]; then BACKUP_NAME="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Microsoft.PowerShell_profile.ps1.backup.$(date +%Y%m%d_%H%M%S)"; mv "$OLD_PROFILE" "$BACKUP_NAME"; echo "✅ Backed up old profile to: $BACKUP_NAME"; else echo "ℹ️  No old OneDrive PowerShell profile found"; fi; OLD_MODULES_DIR="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Modules"; if [[ -d "$OLD_MODULES_DIR" ]]; then BACKUP_MODULES="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Modules.backup.$(date +%Y%m%d_%H%M%S)"; mv "$OLD_MODULES_DIR" "$BACKUP_MODULES"; echo "✅ Backed up old modules directory to: $BACKUP_MODULES"; else echo "ℹ️  No old OneDrive PowerShell modules found"; fi; echo "🎉 Old PowerShell profile cleanup complete!"'

# Diagnose shell startup issues
diagnose-shell:
<<<<<<< HEAD
    @bash scripts/diagnose-shell.sh
=======
    @bash -c 'echo "🔍 Diagnosing shell configuration issues..."; echo ""; echo "📋 Environment variable loading test:"; if source /home/sprime01/dotfiles/scripts/load_env.sh && load_env_file /home/sprime01/dotfiles/mcp/.env; then echo "✅ MCP .env loads successfully"; else echo "❌ MCP .env has issues"; fi; echo ""; echo "📋 Shell common configuration test:"; if P10K_INSTANT_PROMPT=1 source /home/sprime01/dotfiles/.shell_common.sh; then echo "✅ Shell common loads successfully"; else echo "❌ Shell common has issues"; fi; echo ""; echo "📋 Shell functions test:"; if zsh -c "source /home/sprime01/dotfiles/.shell_functions.sh" 2>/dev/null; then echo "✅ Shell functions load without errors"; else echo "❌ Shell functions have parse errors (alias conflicts)"; echo "💡 Run \"just fix-alias-conflicts\""; fi; echo ""; echo "📋 PowerShell profile status:"; WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null || echo "unknown"); PWSH7_PROFILE="/mnt/c/Users/$WIN_USER/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"; if [[ -f "$PWSH7_PROFILE" ]]; then echo "✅ PowerShell 7 profile exists"; else echo "❌ PowerShell 7 profile missing"; echo "💡 Run \"just setup-pwsh7\" to create it"; fi'
>>>>>>> 8336c85 (Refactor dotfiles configuration and remove SSH agent bridge)

# Fix environment loading issues
fix-env-loading:
    @bash scripts/fix-env-loading.sh

# Check for and fix alias/function conflicts
fix-alias-conflicts:
    @bash scripts/fix-alias-conflicts.sh

<<<<<<< HEAD
# Set up Windows SSH Agent to start automatically (requires npiperelay)
setup-ssh-agent-windows:
    @bash scripts/setup-ssh-agent-windows.sh

# Enable SSH agent in zsh (after installing npiperelay)
enable-ssh-agent:
    @bash scripts/enable-ssh-agent.sh

# Set up WSL2 for remote access via SSH and VS Code
setup-wsl2-remote:
    #!/usr/bin/env bash
    echo "🌐 Setting up WSL2 for remote access..."

    # Check if we're in WSL2
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "❌ This command must be run from WSL2"
        echo "💡 This sets up SSH server in WSL2 for remote access"
        exit 1
    fi

    # Run the WSL2 setup script
    ./scripts/setup-wsl2-remote-access.sh

    echo ""
    echo "🎉 WSL2 remote access setup complete!"
    echo "💡 Don't forget to run the Windows configuration script as Administrator"

# Configure Windows for WSL2 remote access (run the PowerShell script)
setup-wsl2-remote-windows:
    #!/usr/bin/env bash
    echo "🪟 Configuring Windows for WSL2 remote access..."

    # Check if we're in WSL2
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "❌ This command is designed for WSL2 environments"
        exit 1
    fi

    # Check if PowerShell is available
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
# old: just run-wizard => bash scripts/setup-wizard-improved.sh
run-wizard:
	@bash scripts/setup-wizard.sh --interactive

# Ensure key scripts are executable in the git index (fixes CI / local runs).
# This target is safe to run locally or in CI to set the executable bit and stage it in git.
fix-permissions:
	@echo "🔧 Ensuring executable bits for known scripts..."
	@chmod +x tools/lint.sh scripts/install-dependencies.sh scripts/setup-pwsh7.sh || true
	@git update-index --chmod=+x tools/lint.sh scripts/install-dependencies.sh scripts/setup-pwsh7.sh >/dev/null 2>&1 || true
	@echo "✅ Permissions updated (if running in a git repo)."
=======
# (SSH-related tasks removed)
>>>>>>> 8336c85 (Refactor dotfiles configuration and remove SSH agent bridge)
