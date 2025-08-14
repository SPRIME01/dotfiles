#!/usr/bin/env bash
# scripts/doctor.sh - quick health checks for dotfiles setup
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_ROOT="${DOTFILES_ROOT:-$REPO_ROOT}"

VERBOSE=0
QUICK=0
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
    -q|--quick) QUICK=1 ;;
  esac
done

log() { [ "$VERBOSE" -eq 1 ] && echo "$*" || true; }
ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
err() { echo "❌ $*"; }

# Active profile
PROFILE_MARKER="${DOTFILES_PROFILE_FILE:-$HOME/.dotfiles-profile}"
if [[ -f "$PROFILE_MARKER" ]]; then
  profile=$(tr -d '\r' < "$PROFILE_MARKER" | head -n1)
  ok "Active profile: ${profile:-unknown}"
else
  warn "No active profile selected (run scripts/select-profile.sh <minimal|developer|full>)"
fi

# Shell & frameworks
command -v zsh >/dev/null 2>&1 && ok "zsh present ($(zsh --version | head -n1))" || warn "zsh not found"
[ -d "$HOME/.oh-my-zsh" ] && ok "Oh My Zsh installed" || warn "Oh My Zsh not installed (~/.oh-my-zsh missing)"
command -v oh-my-posh >/dev/null 2>&1 && ok "oh-my-posh present" || warn "oh-my-posh not found"

# Fonts and Powerlevel10k (best effort)
if [ "$QUICK" -eq 0 ]; then
  # MesloLGS NF check (common local path)
  if ls "$HOME/.local/share/fonts"/MesloLGS\ NF* >/dev/null 2>&1; then
    ok "MesloLGS NF fonts installed"
  else
    warn "MesloLGS NF fonts not found in ~/.local/share/fonts"
  fi
  # P10k theme checkout under Oh My Zsh
  if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    ok "Powerlevel10k theme installed"
  else
    warn "Powerlevel10k not found in Oh My Zsh custom themes"
  fi
fi

# PATH sanity
check_path_dir() {
  local d="$1"
  if [ -d "$d" ]; then
    if [[ ":$PATH:" == *":$d:"* ]]; then
      ok "PATH contains $d"
    else
      warn "PATH missing $d"
    fi
  fi
}
check_path_dir "$HOME/.local/bin"
check_path_dir "$HOME/.cargo/bin"
check_path_dir "$HOME/.pulumi/bin"
VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"; check_path_dir "$VOLTA_HOME/bin"

# MCP config
if [ -d "$DOTFILES_ROOT/mcp" ]; then
  ok "mcp directory present"
  if [ -f "$DOTFILES_ROOT/mcp/servers.json" ]; then
    if command -v jq >/dev/null 2>&1; then
      jq empty "$DOTFILES_ROOT/mcp/servers.json" && ok "servers.json valid JSON" || err "servers.json invalid JSON"
    else
      warn "jq not installed; skipping JSON validation"
    fi
  else
    warn "mcp/servers.json missing"
  fi
else
  warn "mcp directory missing"
fi

# WSL SSH Agent bridge (only check under WSL)
if [ "$QUICK" -eq 0 ] && (grep -qi microsoft /proc/version 2>/dev/null || [ -n "${WSL_DISTRO_NAME:-}" ]); then
  if command -v socat >/dev/null 2>&1; then ok "socat present"; else warn "socat missing (used for SSH bridge)"; fi
  if command -v npiperelay.exe >/dev/null 2>&1 || command -v npiperelay >/dev/null 2>&1; then
    ok "npiperelay present"
  else
    warn "npiperelay not found; SSH agent bridge may not work"
  fi
fi

# VS Code basics
if command -v code >/dev/null 2>&1 || command -v code-insiders >/dev/null 2>&1; then
  ok "VS Code CLI present"
else
  warn "VS Code CLI not found (code)"
fi

# VS Code Linux terminal profile checks (best-effort)
if [ "$QUICK" -eq 0 ] && command -v jq >/dev/null 2>&1; then
  # Candidate settings paths (remote/local). Only check those that exist.
  CANDIDATES=(
    "$HOME/.config/Code/User/settings.json"
    "$HOME/.vscode-server/data/Machine/settings.json"
    "$HOME/.vscode-server/data/User/settings.json"
  )
  for s in "${CANDIDATES[@]}"; do
    if [ -f "$s" ]; then
      # Check defaultProfile.linux
      dprof=$(jq -r '."terminal.integrated.defaultProfile.linux" // empty' "$s" || true)
      if [ -n "$dprof" ]; then
        ok "VS Code defaultProfile.linux=$dprof ($s)"
      else
        warn "VS Code defaultProfile.linux not set ($s)"
      fi
      # Check zsh path if present
      zpath=$(jq -r '."terminal.integrated.profiles.linux".zsh.path // empty' "$s" || true)
      if [ -n "$zpath" ]; then
        if [ -x "$zpath" ]; then ok "VS Code zsh path is executable: $zpath ($s)"; else warn "VS Code zsh path not found/executable: $zpath ($s)"; fi
      fi
      # Check inheritEnv
      inherit=$(jq -r '."terminal.integrated.inheritEnv" // empty' "$s" || true)
      if [ "$inherit" = "true" ] || [ "$inherit" = "false" ]; then
        ok "VS Code inheritEnv=$inherit ($s)"
      fi
    fi
  done
else
  warn "jq not installed; skipping VS Code settings checks"
fi

echo "\nDone."

# Permission audit (non-blocking)
if [ -x "$REPO_ROOT/scripts/permission-audit.sh" ]; then
  echo "\n🔐 Permission audit:"
  bash "$REPO_ROOT/scripts/permission-audit.sh" || true
fi
