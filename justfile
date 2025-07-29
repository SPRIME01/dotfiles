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
