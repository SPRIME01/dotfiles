#!/usr/bin/env bash
set -euo pipefail

# Interactive setup wizard for the dotfiles project.  This script helps you
# configure your preferred shells, install optional components like VS Code
# settings, and enable advanced features such as MCP integration and SSH
# agent bridging.  It detects your environment and calls the appropriate
# installation scripts.  Use this wizard instead of running bootstrap scripts
# manually if you’d like guidance and a summary of actions taken.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Welcome to the dotfiles setup wizard!"
echo "This wizard will help you configure your development environment."
echo

# Helper to prompt with default value
prompt_yes_no() {
  local prompt="$1"
  local default="$2"
  local reply
  if [ "$default" = "y" ]; then
    prompt="$prompt [Y/n] "
  else
    prompt="$prompt [y/N] "
  fi
  read -r -p "$prompt" reply
  reply="${reply:-$default}"
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    return 0
  fi
  return 1
}

# Determine available shells
available_pwsh=0
if command -v pwsh >/dev/null 2>&1; then
  available_pwsh=1
fi

# Ask which shells to configure
configure_bash=0
configure_zsh=0
configure_pwsh=0

if prompt_yes_no "Do you want to configure Bash?" "y"; then
  configure_bash=1
fi
if prompt_yes_no "Do you want to configure Zsh?" "y"; then
  configure_zsh=1
fi
if [ "$available_pwsh" -eq 1 ]; then
  if prompt_yes_no "Do you want to configure PowerShell?" "y"; then
    configure_pwsh=1
  fi
else
  echo "⚠️  PowerShell (pwsh) is not installed; skipping PowerShell configuration."
fi

# Ask about VS Code settings
install_vscode=0
if prompt_yes_no "Install VS Code settings from dotfiles?" "y"; then
  install_vscode=1
fi

# Ask about copying the git hook for alias regeneration
enable_hook=0
if prompt_yes_no "Install post-commit hook to auto-regenerate PowerShell aliases?" "y"; then
  enable_hook=1
fi

# Ask about SSH agent bridge
enable_bridge=0
if prompt_yes_no "Enable WSL2 → Windows SSH agent bridge (WSL only)?" "y"; then
  enable_bridge=1
fi

# Ask about projects directory setup
setup_projects=0
if prompt_yes_no "Set up projects directory with Windows symlink (WSL2 only)?" "y"; then
  setup_projects=1
fi

echo
echo "🔧 Applying your selections..."

# Configure Bash/Zsh by running bootstrap.sh and optional zsh installer
if [ "$configure_bash" -eq 1 ] || [ "$configure_zsh" -eq 1 ]; then
  # Ensure install scripts are executable
  chmod +x "$DOTFILES_ROOT/bootstrap.sh" || true
  chmod +x "$DOTFILES_ROOT/install_zsh.sh" || true
  # Run install_zsh.sh if Zsh selected
  if [ "$configure_zsh" -eq 1 ]; then
    echo "▶️  Installing Oh My Zsh and plugins..."
    bash "$DOTFILES_ROOT/install_zsh.sh"
  fi
  echo "▶️  Running bootstrap.sh to set up Bash/Zsh symlinks and environment..."
  bash "$DOTFILES_ROOT/bootstrap.sh"
fi

# Configure PowerShell
if [ "$configure_pwsh" -eq 1 ]; then
  echo "▶️  Running PowerShell bootstrap script..."
  pwsh -NoProfile -ExecutionPolicy Bypass -File "$DOTFILES_ROOT/bootstrap.ps1"
fi

# Install VS Code settings if requested
if [ "$install_vscode" -eq 1 ]; then
  if [ -f "$DOTFILES_ROOT/install/vscode.sh" ]; then
    echo "▶️  Installing VS Code settings..."
    bash "$DOTFILES_ROOT/install/vscode.sh"
  else
    echo "⚠️  VS Code installer script not found; skipping."
  fi
fi

# Copy git hook
if [ "$enable_hook" -eq 1 ]; then
  HOOK_SRC="$DOTFILES_ROOT/scripts/git-hooks/post-commit"
  HOOK_DEST="$DOTFILES_ROOT/.git/hooks/post-commit"
  if [ -f "$HOOK_SRC" ]; then
    echo "▶️  Installing post-commit hook at .git/hooks/post-commit"
    mkdir -p "$DOTFILES_ROOT/.git/hooks"
    cp "$HOOK_SRC" "$HOOK_DEST"
    chmod +x "$HOOK_DEST"
  else
    echo "⚠️  Hook script not found at $HOOK_SRC; skipping."
  fi
fi

# Remind user about SSH agent bridge
if [ "$enable_bridge" -eq 1 ]; then
  echo "ℹ️  The SSH agent bridge script will run automatically when you open a new Bash or Zsh session."
  echo "    Make sure npiperelay and wsl-ssh-agent-relay are installed on Windows as described in docs/ssh.md."
fi

# Set up projects directory
if [ "$setup_projects" -eq 1 ]; then
  echo "▶️  Setting up projects directory..."

  # Create projects directory
  mkdir -p "$HOME/projects"
  echo "✅ Created ~/projects directory"

  # Create Windows symlink if in WSL2
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
    if [[ -n "$WIN_USER" ]]; then
      WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"
      if [[ ! -e "$WIN_PROJECTS_LINK" ]]; then
        WSL_PROJECTS_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
        echo "🔗 Creating Windows access to projects directory..."

        # Try to create symbolic link first (requires admin privileges)
        if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
          echo "✅ Windows symlink created successfully at C:\\Users\\$WIN_USER\\projects"
          echo "💡 Added to Windows PATH. You can now use 'projects' in Windows terminals!"
        else
          # Fallback: Create a batch file
          BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"
          cat > "$BATCH_FILE" 2>/dev/null << EOF
@echo off
REM Navigate to WSL2 projects directory
echo Opening WSL2 projects directory...
cd /d "\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
cmd /k
EOF
          chmod +x "$BATCH_FILE" 2>/dev/null
          echo "⚠️  Symlink requires admin privileges. Created projects.bat instead."
          echo "💡 To create the symlink manually, run as Administrator:"
          echo "    mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\""
          echo "✅ Alternative: Use 'projects.bat' to access your projects directory"
        fi

        # Add instructions for Windows PATH
        echo ""
        echo "📋 To access projects from any Windows terminal:"
        echo "   1. Add C:\\Users\\$WIN_USER to your Windows PATH environment variable"
        echo "   2. Then type 'projects' (if symlink) or 'projects.bat' in any Windows terminal"
        echo "   3. Or open Windows Explorer and navigate to \\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
        echo ""
        echo "🔧 PowerShell users can also run: Link-WSLProjects"

      else
        echo "✅ Windows projects access already exists"
      fi
    fi
  fi
fi

echo
echo "🎉 Setup complete!  Please restart your terminal sessions to load the new configuration."
