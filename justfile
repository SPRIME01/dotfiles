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
    #!/usr/bin/env bash
    echo "🗂️  Setting up projects directory..."

    # Create projects directory
    mkdir -p ~/projects
    echo "✅ Created ~/projects directory"

    # Create Windows symlink if in WSL2
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
        if [[ -n "$WIN_USER" ]]; then
            WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"
            if [[ ! -e "$WIN_PROJECTS_LINK" ]]; then
                WSL_PROJECTS_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
                echo "🔗 Setting up Windows access to projects directory..."

                # Try to create symbolic link first (requires admin privileges)
                if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
                    echo "✅ Windows symlink created at C:\\Users\\$WIN_USER\\projects"
                else
                    # Fallback: Create a batch file
                    BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"
                    echo '@echo off' > "$BATCH_FILE"
                    echo 'REM Navigate to WSL2 projects directory' >> "$BATCH_FILE"
                    echo 'echo Opening WSL2 projects directory...' >> "$BATCH_FILE"
                    echo 'cd /d "\\wsl.localhost\Ubuntu\home\%USERNAME%\projects"' >> "$BATCH_FILE"
                    echo 'if errorlevel 1 echo Error: Could not access WSL2 projects directory' >> "$BATCH_FILE"
                    echo 'cmd /k' >> "$BATCH_FILE"
                    chmod +x "$BATCH_FILE" 2>/dev/null
                    chmod +x "$BATCH_FILE" 2>/dev/null
                    echo "⚠️  Symlink requires admin privileges. Created projects.bat instead."
                    echo "💡 Manual symlink command (run as Administrator):"
                    echo "    mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\""
                    echo "💡 Or use PowerShell function: Link-WSLProjects"
                fi

                echo ""
                echo "📋 To access from any Windows terminal, add to your PATH:"
                echo "   C:\\Users\\$WIN_USER"
                echo "   Then use: 'projects' (symlink) or 'projects.bat' (batch file)"
                echo ""
                echo "🔧 PowerShell users can also run: Link-WSLProjects"

            else
                echo "✅ Windows projects access already exists"
            fi
        fi
    fi

    echo "🎉 Projects setup complete!"
    echo "💡 Use 'projects' command to navigate to your projects directory"

# Set up PowerShell 7 profile for Windows (requires PowerShell 7 installed)
setup-pwsh7:
    #!/usr/bin/env bash
    echo "🔧 Setting up PowerShell 7 (pwsh) Windows profile..."

    # Check if we're in WSL2
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "❌ This command is designed for WSL2 environments"
        echo "💡 Run this from WSL2 to set up Windows PowerShell 7 profile"
        exit 1
    fi

    # Check if PowerShell 7 is available from Windows
    if ! command -v pwsh.exe >/dev/null 2>&1; then
        echo "❌ PowerShell 7 (pwsh.exe) not found on Windows PATH"
        echo "💡 Install PowerShell 7 from: https://github.com/PowerShell/PowerShell/releases"
        exit 1
    fi

    # Get Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
    if [[ -z "$WIN_USER" ]]; then
        echo "❌ Could not determine Windows username"
        exit 1
    fi

    echo "✅ Detected Windows user: $WIN_USER"

    # Get PowerShell 7 profile path from Windows
    PWSH7_PROFILE=$(pwsh.exe -c '$PROFILE' 2>/dev/null | tr -d '\r' 2>/dev/null)
    if [[ -z "$PWSH7_PROFILE" ]]; then
        echo "❌ Could not get PowerShell 7 profile path"
        exit 1
    fi

    echo "✅ PowerShell 7 profile path: $PWSH7_PROFILE"

    # Convert Windows path to WSL path for manipulation
    PWSH7_PROFILE_WSL=$(echo "$PWSH7_PROFILE" | sed 's|C:\\|/mnt/c/|g' | sed 's|\\|/|g')
    PROFILE_DIR=$(dirname "$PWSH7_PROFILE_WSL")

    # Create profile directory if needed
    if [[ ! -d "$PROFILE_DIR" ]]; then
        mkdir -p "$PROFILE_DIR"
        echo "✅ Created profile directory: $PROFILE_DIR"
    fi

    # Determine dotfiles path for Windows
    DOTFILES_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\dotfiles"
    PROJECTS_WIN_PATH="C:\\Users\\$WIN_USER\\projects"

    # Create the PowerShell 7 profile using printf to avoid escaping issues
    printf '%s\n' \
        "# Windows PowerShell 7 Profile - Generated by dotfiles setup" \
        "# Created: $(date -Iseconds)" \
        "" \
        "# Set execution policy for current user to allow local scripts" \
        "try {" \
        "    if ((Get-ExecutionPolicy -Scope CurrentUser) -eq 'Undefined' -or (Get-ExecutionPolicy -Scope CurrentUser) -eq 'Restricted') {" \
        "        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" \
        "        Write-Host \"✅ Set PowerShell execution policy to RemoteSigned\" -ForegroundColor Green" \
        "    }" \
        "} catch {" \
        "    Write-Warning \"Could not set execution policy: \$(\$_.Exception.Message)\"" \
        "}" \
        "" \
        "# Set environment variables for Windows PowerShell 7" \
        "\$env:DOTFILES_ROOT = \"$DOTFILES_WIN_PATH\"" \
        "\$env:PROJECTS_ROOT = \"$PROJECTS_WIN_PATH\"" \
        "" \
        "# Ensure projects directory exists" \
        "if (-not (Test-Path \$env:PROJECTS_ROOT)) {" \
        "    New-Item -ItemType Directory -Path \$env:PROJECTS_ROOT -Force | Out-Null" \
        "}" \
        "" \
        "# Source the main dotfiles PowerShell profile" \
        "\$mainProfile = Join-Path \$env:DOTFILES_ROOT 'PowerShell\\Microsoft.PowerShell_profile.ps1'" \
        "if (Test-Path \$mainProfile) {" \
        "    try {" \
        "        . \$mainProfile" \
        "        Write-Host \"✅ Loaded dotfiles PowerShell profile\" -ForegroundColor Green" \
        "    } catch {" \
        "        Write-Warning \"Error loading main profile: \$(\$_.Exception.Message)\"" \
        "        # Create basic fallback functions" \
        "        function global:projects { Set-Location -Path \$env:PROJECTS_ROOT }" \
        "        Write-Host \"📦 Created basic functions as fallback\" -ForegroundColor Blue" \
        "    }" \
        "} else {" \
        "    Write-Warning \"Main PowerShell profile not found at: \$mainProfile\"" \
        "    Write-Host \"💡 Ensure WSL2 is running and dotfiles are accessible\" -ForegroundColor Yellow" \
        "    " \
        "    # Create basic fallback functions" \
        "    function global:projects { Set-Location -Path \$env:PROJECTS_ROOT }" \
        "    Write-Host \"📦 Created basic functions as fallback\" -ForegroundColor Blue" \
        "}" \
        > "$PWSH7_PROFILE_WSL"

    echo "✅ Created PowerShell 7 profile"

    # Set execution policy for the current user via PowerShell
    echo "🔐 Setting PowerShell execution policy..."
    pwsh.exe -c "try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Execution policy set successfully' } catch { Write-Warning \"Could not set execution policy: \$(\$_.Exception.Message)\" }" 2>/dev/null || echo "⚠️  Could not set execution policy automatically"
    echo ""
    echo "🧪 Testing PowerShell 7 profile..."

    # Test the profile
    TEST_OUTPUT=$(pwsh.exe -c 'Write-Host "DOTFILES_ROOT:" $env:DOTFILES_ROOT; Write-Host "PROJECTS_ROOT:" $env:PROJECTS_ROOT; if (Get-Command projects -ErrorAction SilentlyContinue) { Write-Host "projects function: Available" } else { Write-Host "projects function: Missing" }' 2>/dev/null)

    if [[ -n "$TEST_OUTPUT" ]]; then
        echo "$TEST_OUTPUT"
        echo "✅ PowerShell 7 profile setup complete!"
    else
        echo "⚠️  Profile created but test failed - may need manual verification"
    fi

    echo ""
    echo "🎉 PowerShell 7 setup complete!"
    echo "💡 Open a new PowerShell 7 window (pwsh) and run 'projects' to test"
    echo "📋 If you still see execution policy warnings, run this in PowerShell as Administrator:"
    echo "    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"

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

# Fix PowerShell 7 profile if it's not working correctly
fix-pwsh7:
    @echo "🔧 Diagnosing and fixing PowerShell 7 profile issues..."
    @just setup-pwsh7

# Set up Windows SSH Agent to start automatically
setup-ssh-agent-windows:
    #!/usr/bin/env bash
    echo "🔐 Setting up Windows SSH Agent auto-start..."
    
    # Check if we're in WSL
    if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
        echo "❌ This command is designed for WSL2 environments"
        echo "💡 Run this from WSL2 to configure Windows SSH Agent"
        exit 1
    fi
    
    # Check if PowerShell is available
    if ! command -v powershell.exe >/dev/null 2>&1; then
        echo "❌ PowerShell not found on Windows"
        exit 1
    fi
    
    echo "▶️  Running Windows SSH Agent setup..."
    powershell.exe -ExecutionPolicy Bypass -File "$PWD/scripts/setup-ssh-agent-windows.ps1"
    
    echo ""
    echo "🎉 Windows SSH Agent setup complete!"
    echo "💡 Your SSH keys should now load automatically when you start PowerShell"
