#!/usr/bin/env bash
# Canonical interactive setup wizard for the dotfiles repository.
# Use this script as the primary entrypoint:
#   bash scripts/setup-wizard.sh [--interactive|--quick|--force]

set -euo pipefail

# Description: Unified interactive setup wizard (consolidated). Provides idempotent,
# state-aware installation for shells, VS Code settings, hooks, projects, SSH bridge,
# and Windows integration. Supersedes previous setup-wizard.sh and setup-wizard-improved.sh.
# Category: setup
# Dependencies: bash, coreutils, (optional) pwsh, powershell.exe (WSL), just
# Idempotent: yes (component state tracked in DOTFILES_STATE_FILE)
# Inputs: environment (WSL_DISTRO_NAME), DOTFILES_STATE_FILE, user prompts
# Outputs: Updated state file, configured shells, optional Windows integration artifacts
# Exit Codes: 0 success, >0 failure

[[ -f "$DOTFILES_ROOT/lib/log.sh" ]] && source "$DOTFILES_ROOT/lib/log.sh"

# Define minimal logging fallbacks if log.sh isn't present
if ! command -v log_info >/dev/null 2>&1; then
  log_info() { echo "[$(date -Iseconds)] [INFO ] $*" >&2; }
fi
if ! command -v log_warn >/dev/null 2>&1; then
  log_warn() { echo "[$(date -Iseconds)] [WARN ] $*" >&2; }
fi

log_info "📦 Unified dotfiles setup wizard start"
echo

prompt_yes_no() {
  local prompt="$1" default="$2" reply
  if [ "$default" = y ]; then prompt+=" [Y/n] "; else prompt+=" [y/N] "; fi
  read -r -p "$prompt" reply || reply=""
  reply="${reply:-$default}"; [[ $reply =~ ^[Yy]$ ]]
}

safe_execute() {
  local component="$1" description="$2" command="$3"
  echo "▶️  $description..."
  if eval "$command"; then
    mark_component_installed "$component"; echo "✅ $description"; return 0
  else
    mark_component_failed "$component" "$description failed"; echo "❌ $description"; return 1
  fi
}

if has_any_setup_been_done; then
  log_info "Displaying current installation status"; show_installation_status; echo
  failed_components=$(get_failed_components || true)
  if [[ -n "$failed_components" ]]; then
    echo "⚠️  Failed previously:"; echo "$failed_components"; echo
    prompt_yes_no "Retry failed components only?" n && RETRY_FAILED_ONLY=true || RETRY_FAILED_ONLY=false
  else
    RETRY_FAILED_ONLY=false
  fi
  prompt_yes_no "Force reinstall all components?" n && FORCE_REINSTALL=true || FORCE_REINSTALL=false
else
  echo "🚀 First run detected."; RETRY_FAILED_ONLY=false; FORCE_REINSTALL=false
fi

available_pwsh=0; command -v pwsh >/dev/null 2>&1 && available_pwsh=1 || true

# Component flags
configure_bash=0; configure_zsh=0; configure_pwsh=0; install_vscode=0; enable_hook=0; enable_bridge=0
setup_projects=0; setup_pwsh7_windows=0; setup_ssh_agent_windows=0

if [[ "$RETRY_FAILED_ONLY" == true ]]; then
  echo "🔄 Retrying only failed components..."
  for c in bash_config zsh_config pwsh_config vscode_settings git_hook ssh_bridge projects_setup pwsh7_windows ssh_agent_windows; do
    if grep -q "^${c}=failed" "${DOTFILES_STATE_FILE}" 2>/dev/null; then
      case $c in
        bash_config) configure_bash=1 ;; zsh_config) configure_zsh=1 ;; pwsh_config) configure_pwsh=1 ;;
        vscode_settings) install_vscode=1 ;; git_hook) enable_hook=1 ;; ssh_bridge) enable_bridge=1 ;;
        projects_setup) setup_projects=1 ;; pwsh7_windows) setup_pwsh7_windows=1 ;; ssh_agent_windows) setup_ssh_agent_windows=1 ;;
      esac
      echo "🔄 Will retry: $c"
    fi
  done
else
  log_info "Gathering user choices"; echo
  smart_prompt_yes_no bash_config "Configure Bash?" y "$FORCE_REINSTALL" && configure_bash=1
  smart_prompt_yes_no zsh_config "Configure Zsh?" y "$FORCE_REINSTALL" && configure_zsh=1
  if (( available_pwsh )); then
    smart_prompt_yes_no pwsh_config "Configure PowerShell?" y "$FORCE_REINSTALL" && configure_pwsh=1 || true
  else
    mark_component_skipped pwsh_config "PowerShell not available"
  fi
  smart_prompt_yes_no vscode_settings "Install VS Code settings?" y "$FORCE_REINSTALL" && install_vscode=1
  smart_prompt_yes_no git_hook "Install post-commit alias hook?" y "$FORCE_REINSTALL" && enable_hook=1
  smart_prompt_yes_no ssh_bridge "Enable WSL→Windows SSH agent bridge?" y "$FORCE_REINSTALL" && enable_bridge=1
  smart_prompt_yes_no projects_setup "Setup projects directory (WSL2)?" y "$FORCE_REINSTALL" && setup_projects=1
  if [[ -n ${WSL_DISTRO_NAME:-} ]] && command -v cmd.exe >/dev/null 2>&1; then
    command -v pwsh.exe >/dev/null 2>&1 && smart_prompt_yes_no pwsh7_windows "Setup Windows pwsh7 profile?" y "$FORCE_REINSTALL" && setup_pwsh7_windows=1 || mark_component_skipped pwsh7_windows "pwsh7 not on Windows"
    command -v powershell.exe >/dev/null 2>&1 && smart_prompt_yes_no ssh_agent_windows "Setup Windows SSH Agent?" y "$FORCE_REINSTALL" && setup_ssh_agent_windows=1 || mark_component_skipped ssh_agent_windows "Windows PowerShell missing"
  else
    mark_component_skipped pwsh7_windows "Not WSL"; mark_component_skipped ssh_agent_windows "Not WSL"
  fi
fi

# Apply selections
echo; log_info "Applying selections"; overall_success=true

# Run bootstrap first when either shell is selected (ensures bash_config runs before zsh_config)
if (( configure_bash || configure_zsh )); then
  chmod +x "$DOTFILES_ROOT/bootstrap.sh" || true
  safe_execute bash_config "Setting up shell symlinks and environment" "bash '$DOTFILES_ROOT/bootstrap.sh'" || overall_success=false
fi

# Then install zsh (Oh My Zsh/plugins) so zsh_config observes bootstrap precondition
if (( configure_zsh )); then
  chmod +x "$DOTFILES_ROOT/install_zsh.sh" || true
  safe_execute zsh_config "Installing Oh My Zsh and plugins" "bash '$DOTFILES_ROOT/install_zsh.sh'" || overall_success=false
fi

if (( configure_pwsh ))
(( configure_pwsh )) && safe_execute pwsh_config "Setting up PowerShell configuration" "pwsh -NoProfile -ExecutionPolicy Bypass -File '$DOTFILES_ROOT/bootstrap.ps1'" || true

if (( install_vscode )); then
  if [ -f "$DOTFILES_ROOT/install/vscode.sh" ]; then
    safe_execute vscode_settings "Installing VS Code settings" "bash '$DOTFILES_ROOT/install/vscode.sh'" || overall_success=false
  else
    echo "⚠️  VS Code installer missing"; mark_component_failed vscode_settings missing; overall_success=false
  fi
fi

if (( enable_hook )); then
  HOOK_SRC="$DOTFILES_ROOT/scripts/git-hooks/post-commit"; HOOK_DEST="$DOTFILES_ROOT/.git/hooks/post-commit"
  if [ -f "$HOOK_SRC" ]; then
    if [[ ! -f $HOOK_DEST || $HOOK_SRC -nt $HOOK_DEST ]]; then
      if mkdir -p "$(dirname "$HOOK_DEST")" && cp "$HOOK_SRC" "$HOOK_DEST" && chmod +x "$HOOK_DEST"; then
        mark_component_installed git_hook; echo "✅ Git hook installed/updated"
      else
        mark_component_failed git_hook copy_failed; overall_success=false
      fi
    else
      echo "✅ Git hook already current"; mark_component_installed git_hook
    fi
  else
    log_warn "Git hook source missing"; mark_component_failed git_hook missing; overall_success=false
  fi
fi

if (( enable_bridge )); then
  echo "ℹ️  SSH agent bridge will rely on shell startup configuration."; mark_component_installed ssh_bridge
fi

if (( setup_projects )); then
  echo "▶️  Ensuring projects directory"; mkdir -p "$HOME/projects"; projects_success=true
  if [[ -n ${WSL_DISTRO_NAME:-} ]] && command -v cmd.exe >/dev/null 2>&1; then
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || true)
    if [[ -n $WIN_USER ]]; then
      WIN_PROJECTS_LINK="/mnt/c/Users/$WIN_USER/projects"; BATCH_FILE="/mnt/c/Users/$WIN_USER/projects.bat"
      if [[ -L $WIN_PROJECTS_LINK && -d $WIN_PROJECTS_LINK ]]; then
        echo "✅ Windows symlink exists"
      elif [[ -d $WIN_PROJECTS_LINK ]]; then
        echo "ℹ️  Windows projects directory exists (not symlink)"
      else
        WSL_PROJECTS_WIN_PATH="\\\\wsl.localhost\\$WSL_DISTRO_NAME\\home\\$USER\\projects"
        if cmd.exe /c "mklink /D \"C:\\Users\\$WIN_USER\\projects\" \"$WSL_PROJECTS_WIN_PATH\"" >/dev/null 2>&1; then
          echo "✅ Created Windows symlink"
        else
          if [[ ! -f $BATCH_FILE ]]; then
            cat > "$BATCH_FILE" <<'EOF'
@echo off

cd /d "\\wsl.localhost\%WSL_DISTRO_NAME%\home\$USER\projects" || echo Failed to access projects
cmd /k
EOF
            chmod +x "$BATCH_FILE" 2>/dev/null || true; echo "✅ Created projects.bat fallback"
          else
            echo "✅ Batch fallback already present"
          fi
        fi
      fi
    else
      echo "⚠️  Could not determine Windows username"; projects_success=false
    fi
  fi
  if $projects_success; then mark_component_installed projects_setup; else mark_component_failed projects_setup windows_integration; overall_success=false; fi
fi

(( setup_pwsh7_windows )) && safe_execute pwsh7_windows "Setting up PowerShell 7 Windows integration" "bash '$DOTFILES_ROOT/scripts/setup-pwsh7.sh'" || true
if (( setup_ssh_agent_windows )); then
  if [[ -f "$DOTFILES_ROOT/scripts/setup-ssh-agent-windows-simple.ps1" ]]; then
    safe_execute ssh_agent_windows "Setting up Windows SSH Agent" "powershell.exe -ExecutionPolicy Bypass -File '$DOTFILES_ROOT/scripts/setup-ssh-agent-windows-simple.ps1'" || overall_success=false
  else
    echo "⚠️  SSH Agent setup script missing"; mark_component_failed ssh_agent_windows missing; overall_success=false
  fi
fi

echo; echo "=================================================="
if $overall_success; then
  echo "🎉 Setup completed successfully!"
else
  echo "⚠️  Setup completed with some issues. Re-run to retry failures."
fi
echo; echo "📋 Final installation status:"; show_installation_status; echo
echo "🚀 Next steps: restart terminal or 'source ~/.zshrc'; run 'p10k configure' if desired."
echo "setup_completed=$(date -Iseconds)" >> "$DOTFILES_STATE_FILE" || true
if [ "$enable_hook" -eq 1 ]; then
