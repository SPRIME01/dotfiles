#!/usr/bin/env bash
set -euo pipefail

# Interactive setup wizard for the dotfiles project.  This script helps you
# configure your preferred shells, install optional components like VS Code
# settings, and enable advanced features such as MCP integration and SSH
# agent bridging.  It detects your environment and calls the appropriate
# installation scripts.  Use this wizard instead of running bootstrap scripts
# manually if you'd like guidance and a summary of actions taken.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load state management functions
source "$DOTFILES_ROOT/lib/state-management.sh"

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

# Show current installation status if any setup has been done
if has_any_setup_been_done; then
    echo "📋 Current installation status:"
    show_installation_status
    echo

    # Check for failed components and offer to retry
    failed_components=$(get_failed_components)
    if [[ -n "$failed_components" ]]; then
        echo "⚠️  Some components failed in previous runs:"
        echo "$failed_components"
        echo
        if prompt_yes_no "Would you like to retry failed components only?" "n"; then
            # Set flags to only retry failed components
            RETRY_FAILED_ONLY=true
        else
            RETRY_FAILED_ONLY=false
        fi
    else
        RETRY_FAILED_ONLY=false
    fi
else
    echo "🚀 This appears to be your first time running the setup wizard."
    RETRY_FAILED_ONLY=false
fi

# Determine available shells
available_pwsh=0
if command -v pwsh >/dev/null 2>&1; then
  available_pwsh=1
fi

# Ask which shells to configure (using smart prompts)
configure_bash=0
configure_zsh=0
configure_pwsh=0

# Only prompt for components that aren't installed or if retrying failed ones
if [[ "$RETRY_FAILED_ONLY" == "true" ]]; then
    echo "🔄 Retrying failed components only..."
    # Check each component and set flags based on failure status
    if grep -q "^bash_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
        configure_bash=1
    fi
    if grep -q "^zsh_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
        configure_zsh=1
    fi
    if grep -q "^pwsh_config=failed" "$DOTFILES_STATE_FILE" 2>/dev/null; then
        configure_pwsh=1
    fi
else
    # Normal prompting with smart state checking
    if smart_prompt_yes_no "bash_config" "Do you want to configure Bash?" "y"; then
      configure_bash=1
    fi
    if smart_prompt_yes_no "zsh_config" "Do you want to configure Zsh?" "y"; then
      configure_zsh=1
    fi
    if [ "$available_pwsh" -eq 1 ]; then
      if smart_prompt_yes_no "pwsh_config" "Do you want to configure PowerShell?" "y"; then
        configure_pwsh=1
      fi
    else
      echo "⚠️  PowerShell (pwsh) is not installed; skipping PowerShell configuration."
      mark_component_skipped "pwsh_config" "PowerShell not available"
    fi
fi

# Ask about VS Code settings
install_vscode=0
if prompt_yes_no "Install VS Code settings from dotfiles?" "y"; then
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

# Ask about PowerShell 7 Windows integration (WSL2 only)
setup_pwsh7_windows=0
if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
  if command -v pwsh.exe >/dev/null 2>&1; then
    if prompt_yes_no "Set up PowerShell 7 profile for Windows integration?" "y"; then
      setup_pwsh7_windows=1
    fi
  else
    echo "ℹ️  PowerShell 7 (pwsh.exe) not detected on Windows; skipping Windows PowerShell 7 setup."
  fi
fi

# Ask about Windows SSH Agent setup (WSL2 only)
setup_ssh_agent_windows=0
if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v cmd.exe >/dev/null 2>&1; then
  if command -v powershell.exe >/dev/null 2>&1; then
    if prompt_yes_no "Set up Windows SSH Agent for automatic startup?" "y"; then
      setup_ssh_agent_windows=1
    fi
  else
    echo "ℹ️  PowerShell not detected on Windows; skipping SSH Agent setup."
  fi
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
    echo "▶️  Installing VS Code settings..."
    bash "$DOTFILES_ROOT/install/vscode.sh"
  else
    echo "⚠️  VS Code installer script not found; skipping."
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

# Set up PowerShell 7 Windows integration
if [ "$setup_pwsh7_windows" -eq 1 ]; then
  echo "▶️  Setting up PowerShell 7 Windows integration..."

  # Use the just command for consistency
  if command -v just >/dev/null 2>&1; then
    just setup-pwsh7
  else
    # Fallback to manual setup if just is not available
    echo "ℹ️  'just' command not found, using manual setup..."

    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
    if [[ -n "$WIN_USER" ]]; then
      # Get PowerShell 7 profile path
      PWSH7_PROFILE=$(pwsh.exe -c '$PROFILE' 2>/dev/null | tr -d '\r' 2>/dev/null)

      if [[ -n "$PWSH7_PROFILE" ]]; then
        # Convert to WSL path and create profile
        PWSH7_PROFILE_WSL=$(echo "$PWSH7_PROFILE" | sed 's|C:\\|/mnt/c/|g' | sed 's|\\|/|g')
        PROFILE_DIR=$(dirname "$PWSH7_PROFILE_WSL")

        mkdir -p "$PROFILE_DIR" 2>/dev/null

        cat > "$PWSH7_PROFILE_WSL" << EOF
# Windows PowerShell 7 Profile - Generated by dotfiles setup wizard

# Set execution policy for current user to allow local scripts
try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -eq 'Undefined' -or (Get-ExecutionPolicy -Scope CurrentUser) -eq 'Restricted') {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✅ Set PowerShell execution policy to RemoteSigned" -ForegroundColor Green
    }
} catch {
    Write-Warning "Could not set execution policy: \$(\$_.Exception.Message)"
}

\$env:DOTFILES_ROOT = "\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\dotfiles"
\$env:PROJECTS_ROOT = "C:\\Users\\$WIN_USER\\projects"

if (-not (Test-Path \$env:PROJECTS_ROOT)) {
    New-Item -ItemType Directory -Path \$env:PROJECTS_ROOT -Force | Out-Null
}

\$mainProfile = Join-Path \$env:DOTFILES_ROOT 'PowerShell\\Microsoft.PowerShell_profile.ps1'
if (Test-Path \$mainProfile) {
    try {
        . \$mainProfile
        Write-Host "✅ Loaded dotfiles PowerShell profile" -ForegroundColor Green
    } catch {
        function global:projects { Set-Location -Path \$env:PROJECTS_ROOT }
        Write-Host "📦 Created basic functions as fallback" -ForegroundColor Blue
    }
} else {
    function global:projects { Set-Location -Path \$env:PROJECTS_ROOT }
    Write-Host "📦 Created basic functions as fallback" -ForegroundColor Blue
}
EOF
        echo "✅ PowerShell 7 profile created successfully"

        # Set execution policy
        echo "🔐 Setting PowerShell execution policy..."
        pwsh.exe -c "try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Write-Host 'Execution policy set successfully' } catch { Write-Warning \"Could not set execution policy: \$(\$_.Exception.Message)\" }" 2>/dev/null || echo "⚠️  Could not set execution policy automatically"

        echo "💡 Open a new PowerShell 7 window (pwsh) and run 'projects' to test"
      else
        echo "⚠️  Could not determine PowerShell 7 profile path"
      fi
    else
      echo "⚠️  Could not determine Windows username"
    fi
  fi
fi

# Set up Windows SSH Agent
if [ "$setup_ssh_agent_windows" -eq 1 ]; then
  echo "▶️  Setting up Windows SSH Agent..."

  # Use the just command for consistency
  if command -v just >/dev/null 2>&1; then
    just setup-ssh-agent-windows
  else
    # Fallback to direct PowerShell execution
    echo "ℹ️  'just' command not found, using direct setup..."
    powershell.exe -ExecutionPolicy Bypass -File "$PWD/scripts/setup-ssh-agent-windows.ps1" 2>/dev/null || echo "⚠️  Could not set up SSH Agent automatically"
  fi
fi

echo
echo "🎉 Setup complete!  Please restart your terminal sessions to load the new configuration."
