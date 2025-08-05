#!/usr/bin/env bash
# Idempotent projects directory setup script
# This script safely sets up projects directory with Windows integration

set -e

echo "🗂️  Setting up projects directory..."

# Always safe to create the directory
mkdir -p ~/projects
echo "✅ Projects directory ensured at ~/projects"

# Check if we're in WSL2 environment
if [[ -z "${WSL_DISTRO_NAME:-}" ]] || ! command -v cmd.exe >/dev/null 2>&1; then
    echo "ℹ️  Not in WSL2 environment, skipping Windows integration"
    echo "🎉 Projects setup complete!"
    exit 0
fi

# Get Windows username
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d "\r" 2>/dev/null)
if [[ -z "$WIN_USER" ]]; then
    echo "❌ Could not determine Windows username"
    exit 1
fi

WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"
WSL_PROJECTS_WIN_PATH="\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"

echo "🔗 Setting up Windows access to projects directory..."

# Check current state
if [[ -L "$WIN_PROJECTS_LINK" ]] && [[ -d "$WIN_PROJECTS_LINK" ]]; then
    echo "✅ Windows symlink already exists and is working"
    LINK_STATUS="symlink_exists"
elif [[ -d "$WIN_PROJECTS_LINK" ]]; then
    echo "ℹ️  Windows projects directory already exists (not a symlink)"
    echo "💡 If you want to replace it with a symlink, manually remove it first:"
    echo "    rm -rf '/mnt/c/Users/$WIN_USER/projects'"
    LINK_STATUS="directory_exists"
elif [[ -f "$WIN_PROJECTS_LINK" ]]; then
    echo "⚠️  A file exists at the projects location"
    echo "💡 Please remove: /mnt/c/Users/$WIN_USER/projects"
    LINK_STATUS="file_conflict"
else
    echo "🔗 Creating Windows symlink..."

    # Try to create symbolic link (requires admin privileges)
    if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
        echo "✅ Windows symlink created at C:\\Users\\$WIN_USER\\projects"
        LINK_STATUS="symlink_created"
    else
        echo "⚠️  Symlink creation requires Administrator privileges"
        LINK_STATUS="symlink_failed"
    fi
fi

# Handle batch file creation (only if symlink doesn't exist)
if [[ "$LINK_STATUS" != "symlink_exists" ]] && [[ "$LINK_STATUS" != "symlink_created" ]]; then
    if [[ ! -f "$BATCH_FILE" ]]; then
        echo "📝 Creating batch file fallback..."
        cat > "$BATCH_FILE" << EOF
@echo off
REM Navigate to WSL2 projects directory
echo Opening WSL2 projects directory...
cd /d "$WSL_PROJECTS_WIN_PATH"
if errorlevel 1 (
    echo Error: Could not access WSL2 projects directory
    echo Make sure WSL2 is running and the path is correct
    pause
) else (
    echo Successfully opened WSL2 projects directory
)
cmd /k
EOF
        # Make executable (Windows will handle this properly)
        chmod +x "$BATCH_FILE" 2>/dev/null || true
        echo "✅ Created projects.bat"
    else
        echo "✅ Batch file already exists"
    fi

    echo ""
    echo "💡 To use the batch file:"
    echo "   1. Add C:\\Users\\$WIN_USER to your Windows PATH"
    echo "   2. Open any Windows terminal and type: projects"
    echo ""
    echo "💡 To create the symlink manually (run as Administrator in Windows):"
    echo "   mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\""
fi

echo ""
echo "📋 Windows integration summary:"
case "$LINK_STATUS" in
    "symlink_exists"|"symlink_created")
        echo "✅ Symlink: C:\\Users\\$WIN_USER\\projects → WSL2 projects"
        echo "✅ Access: Use 'projects' command or browse in Windows Explorer"
        ;;
    "directory_exists")
        echo "ℹ️  Directory exists but is not a symlink"
        echo "⚠️  Manual action needed if you want symlink functionality"
        ;;
    "symlink_failed")
        echo "❌ Symlink creation failed (needs Administrator privileges)"
        echo "✅ Batch file available as fallback"
        ;;
    "file_conflict")
        echo "❌ File conflict at target location"
        echo "⚠️  Manual cleanup needed"
        ;;
esac

# Add PowerShell function information
if command -v pwsh.exe >/dev/null 2>&1; then
    echo ""
    echo "🔧 PowerShell users can also use the Link-WSLProjects function"
    echo "   (available in the dotfiles PowerShell profile)"
fi

echo ""
echo "🎉 Projects setup complete!"
echo "💡 Use the 'projects' command to navigate to your projects directory"
