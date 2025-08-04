# Justfile for dotfiles project

# This Justfile defines common tasks for setting up, testing and maintaining
# the dotfiles project.  Just is a cross‑platform command runner similar to
# Make but with a simpler syntax.  See <https://github.com/casey/just> for
# installation instructions on your platform.

# Display a list of available tasks when no target is specified.
default:
    @just --list

# Run all automated tests.  This will execute shell tests and PowerShell
# tests (if pwsh is available) to verify that environment loaders and other
# components behave correctly.
test:
    @bash scripts/run-tests.sh

# Launch the interactive setup wizard for Unix shells.  This script
# guides you through configuring shells, installing optional components
# like VS Code settings, and enabling MCP/SSH integration.
setup:
    @bash scripts/setup-wizard.sh

# Launch the interactive setup wizard for Windows using PowerShell.  Use this
# target if you’re on Windows and have PowerShell 7 installed.  The wizard
# will call the PowerShell bootstrap script and other installers.
setup-windows:
    @pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/setup-wizard.ps1

# Update the dotfiles repository by pulling the latest changes and
# reapplying configurations.  This wraps the update.sh script.
update:
    @bash update.sh

# Set up projects directory and Windows symlink (WSL2 only)
setup-projects:
    @bash -c 'echo "🗂️  Setting up projects directory..."; mkdir -p ~/projects; echo "✅ Created ~/projects directory"; if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null); if [[ -n "$WIN_USER" ]]; then WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"; if [[ ! -e "$WIN_PROJECTS_LINK" ]]; then WSL_PROJECTS_WIN_PATH="\\wsl.localhost\$WSL_DISTRO_NAME\home\$USER\projects"; echo "🔗 Setting up Windows access to projects directory..."; if cmd.exe /c "mklink /D \"C:\Users\$WIN_USER\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then echo "✅ Windows symlink created at C:\Users\$WIN_USER\projects"; else BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"; echo "@echo off" > "$BATCH_FILE"; echo "REM Navigate to WSL2 projects directory" >> "$BATCH_FILE"; echo "echo Opening WSL2 projects directory..." >> "$BATCH_FILE"; echo "cd /d \"\\wsl.localhost\Ubuntu\home\%USERNAME%\projects\"" >> "$BATCH_FILE"; echo "if errorlevel 1 echo Error: Could not access WSL2 projects directory" >> "$BATCH_FILE"; echo "cmd /k" >> "$BATCH_FILE"; chmod +x "$BATCH_FILE" 2>/dev/null; echo "⚠️  Symlink requires admin privileges. Created projects.bat instead."; echo "💡 Manual symlink command (run as Administrator):"; echo "    mklink /D \"C:\Users\$WIN_USER\projects\" \"$WSL_PROJECTS_WIN_PATH\""; echo "💡 Or use PowerShell function: Link-WSLProjects"; fi; echo ""; echo "📋 To access from any Windows terminal, add to your PATH:"; echo "   C:\Users\$WIN_USER"; echo "   Then use: \"projects\" (symlink) or \"projects.bat\" (batch file)"; echo ""; echo "🔧 PowerShell users can also run: Link-WSLProjects"; else echo "✅ Windows projects access already exists"; fi; fi; fi; echo "🎉 Projects setup complete!"; echo "💡 Use \"projects\" command to navigate to your projects directory"'

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
    @echo "   • Fixed shell configuration (no startup errors)"
    @echo ""
    @echo "⚠️  SSH agent is disabled by default (npiperelay required)"
    @echo "💡 To enable SSH agent: install npiperelay, then run 'just enable-ssh-agent'"

# Fix PowerShell 7 profile if it's not working correctly
fix-pwsh7:
    @echo "🔧 Diagnosing and fixing PowerShell 7 profile issues..."
    @just setup-pwsh7

# Clean up old PowerShell profiles that might conflict
clean-old-powershell-profiles:
    @bash -c 'echo "🧹 Cleaning up old PowerShell profiles..."; WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null); OLD_PROFILE="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Microsoft.PowerShell_profile.ps1"; if [[ -f "$OLD_PROFILE" ]]; then BACKUP_NAME="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Microsoft.PowerShell_profile.ps1.backup.$(date +%Y%m%d_%H%M%S)"; mv "$OLD_PROFILE" "$BACKUP_NAME"; echo "✅ Backed up old profile to: $BACKUP_NAME"; else echo "ℹ️  No old OneDrive PowerShell profile found"; fi; OLD_MODULES_DIR="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Modules"; if [[ -d "$OLD_MODULES_DIR" ]]; then BACKUP_MODULES="/mnt/c/Users/$WIN_USER/OneDrive/MyDocuments/PowerShell/Modules.backup.$(date +%Y%m%d_%H%M%S)"; mv "$OLD_MODULES_DIR" "$BACKUP_MODULES"; echo "✅ Backed up old modules directory to: $BACKUP_MODULES"; else echo "ℹ️  No old OneDrive PowerShell modules found"; fi; echo "🎉 Old PowerShell profile cleanup complete!"'

# Diagnose shell startup issues
diagnose-shell:
    @bash -c 'echo "🔍 Diagnosing shell configuration issues..."; echo ""; echo "📋 Environment variable loading test:"; if source /home/sprime01/dotfiles/scripts/load_env.sh && load_env_file /home/sprime01/dotfiles/mcp/.env; then echo "✅ MCP .env loads successfully"; else echo "❌ MCP .env has issues"; fi; echo ""; echo "📋 Shell common configuration test:"; if P10K_INSTANT_PROMPT=1 source /home/sprime01/dotfiles/.shell_common.sh; then echo "✅ Shell common loads successfully"; else echo "❌ Shell common has issues"; fi; echo ""; echo "📋 Shell functions test:"; if zsh -c "source /home/sprime01/dotfiles/.shell_functions.sh" 2>/dev/null; then echo "✅ Shell functions load without errors"; else echo "❌ Shell functions have parse errors (alias conflicts)"; echo "💡 Run \"just fix-alias-conflicts\""; fi; echo ""; echo "📋 SSH agent configuration:"; if grep -q "^# if \[ -f \"\\$HOME/dotfiles/zsh/ssh-agent.zsh\" \]; then" /home/sprime01/dotfiles/.zshrc; then echo "⏸️  SSH agent is disabled (npiperelay not available)"; echo "💡 Run \"just enable-ssh-agent\" after installing npiperelay"; elif grep -q "if \[ -f \"\\$HOME/dotfiles/zsh/ssh-agent.zsh\" \]; then" /home/sprime01/dotfiles/.zshrc; then echo "✅ SSH agent is enabled"; else echo "❓ SSH agent configuration status unclear"; fi; echo ""; echo "📋 PowerShell profile status:"; WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null || echo "unknown"); PWSH7_PROFILE="/mnt/c/Users/$WIN_USER/Documents/PowerShell/Microsoft.PowerShell_profile.ps1"; if [[ -f "$PWSH7_PROFILE" ]]; then echo "✅ PowerShell 7 profile exists"; else echo "❌ PowerShell 7 profile missing"; echo "💡 Run \"just setup-pwsh7\" to create it"; fi'

# Fix environment loading issues
fix-env-loading:
    @bash -c 'echo "🔧 Fixing environment loading issues..."; if [[ ! -f "/home/sprime01/dotfiles/scripts/load_env.sh" ]]; then echo "❌ load_env.sh missing"; exit 1; fi; echo "🧪 Testing environment loading..."; if source /home/sprime01/dotfiles/scripts/load_env.sh && load_env_file /home/sprime01/dotfiles/mcp/.env 2>/dev/null; then echo "✅ Environment loading works correctly"; else echo "❌ Environment loading has issues"; echo "💡 The load_env.sh script or MCP .env file may need attention"; exit 1; fi; echo "🎉 Environment loading is working correctly!"'

# Check for and fix alias/function conflicts
fix-alias-conflicts:
    @bash -c 'echo "🔧 Checking for alias/function conflicts..."; echo ""; echo "📋 Known conflicts:"; if grep -q "unalias dps" /home/sprime01/dotfiles/.shell_functions.sh; then echo "✅ dps conflict fixed"; else echo "❌ dps conflict may exist"; fi; if grep -q "unalias gclean" /home/sprime01/dotfiles/.shell_functions.sh; then echo "✅ gclean conflict fixed"; else echo "❌ gclean conflict may exist"; fi; echo ""; echo "🧪 Testing shell functions loading..."; if zsh -c "source /home/sprime01/dotfiles/.shell_functions.sh" 2>/dev/null; then echo "✅ Shell functions load without errors"; else echo "❌ Shell functions have parse errors"; echo "💡 Check for alias/function conflicts"; exit 1; fi; echo "🎉 No alias conflicts detected!"'

# Set up Windows SSH Agent to start automatically (requires npiperelay)
setup-ssh-agent-windows:
    #!/usr/bin/env bash
    echo "🔐 Setting up Windows SSH Agent auto-start..."
    echo "⚠️  Note: SSH agent is currently disabled in .zshrc due to missing npiperelay"
    echo "💡 To enable SSH agent, first install npiperelay via Scoop:"
    echo "   scoop install npiperelay"
    echo "💡 Then uncomment SSH agent setup in .zshrc"

    # Check if we're in WSL
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "❌ This command is designed for WSL2 environments"
        echo "💡 Run this from WSL2 to configure Windows SSH Agent"
        exit 1
    fi

    # Check if npiperelay is installed
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
    NPIPERELAY_PATH="/mnt/c/Users/$WIN_USER/scoop/apps/npiperelay/0.1.0/npiperelay.exe"

    if [[ ! -x "$NPIPERELAY_PATH" ]]; then
        echo "❌ npiperelay not found at $NPIPERELAY_PATH"
        echo "💡 Install npiperelay first: scoop install npiperelay"
        exit 1
    fi

    # Check if PowerShell is available
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "❌ PowerShell not found on Windows"
        exit 1
    fi

    echo "▶️  Running Windows SSH Agent setup..."
    powershell.exe -ExecutionPolicy Bypass -File "$PWD/scripts/setup-ssh-agent-windows-simple.ps1"

    echo ""
    echo "🎉 Windows SSH Agent setup complete!"
    echo "💡 Your SSH keys should now load automatically when you start PowerShell"
    echo "💡 To enable in zsh, uncomment SSH agent setup in .zshrc"

# Enable SSH agent in zsh (after installing npiperelay)
enable-ssh-agent:
    @bash -c 'echo "🔐 Enabling SSH agent in zsh configuration..."; WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null); NPIPERELAY_PATH="/mnt/c/Users/$WIN_USER/scoop/apps/npiperelay/0.1.0/npiperelay.exe"; if [[ ! -x "$NPIPERELAY_PATH" ]]; then echo "❌ npiperelay not found at $NPIPERELAY_PATH"; echo "💡 Install npiperelay first: scoop install npiperelay"; echo "💡 Then run: just enable-ssh-agent"; exit 1; fi; if grep -q "^# if \[ -f \"\\$HOME/dotfiles/zsh/ssh-agent.zsh\" \]; then" /home/sprime01/dotfiles/.zshrc; then sed -i "s/^# if \[ -f \"\\$HOME\\/dotfiles\\/zsh\\/ssh-agent\\.zsh\" \]; then$/if [ -f \"\\$HOME\\/dotfiles\\/zsh\\/ssh-agent.zsh\" ]; then/" /home/sprime01/dotfiles/.zshrc; sed -i "s/^#     \\. \"\\$HOME\\/dotfiles\\/zsh\\/ssh-agent\\.zsh\"$/    . \"\\$HOME\\/dotfiles\\/zsh\\/ssh-agent.zsh\"/" /home/sprime01/dotfiles/.zshrc; sed -i "s/^# fi$/fi/" /home/sprime01/dotfiles/.zshrc; echo "✅ SSH agent enabled in .zshrc"; echo "💡 Restart your terminal or run \"source ~/.zshrc\" to activate"; else echo "⚠️  SSH agent setup not found in commented form in .zshrc"; echo "💡 Manual edit may be required"; fi'

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