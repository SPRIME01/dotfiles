#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrap to install chezmoi (if missing) and apply this repo.
# Usage:
#   ./install.sh                # apply with source = current repo directory
#   CHEZMOI_SOURCE=/path/to/src ./install.sh
#   DRY_RUN=1 ./install.sh      # plan only, do not apply

echo "==> Dotfiles bootstrap: chezmoi apply"

SOURCE_DIR=${CHEZMOI_SOURCE:-"$(pwd -P)"}
DRY_RUN=${DRY_RUN:-0}

echo "• Source directory: $SOURCE_DIR"

# Ensure chezmoi never invokes a pager in this script
export CHEZMOI_NO_PAGER=1
export PAGER=cat

if command -v chezmoi >/dev/null 2>&1; then
  echo "• chezmoi detected: $(chezmoi --version | head -n1)"
else
  echo "• Installing chezmoi via official installer (requires network)"
  if command -v curl >/dev/null 2>&1; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  elif command -v wget >/dev/null 2>&1; then
    sh -c "$(wget -qO- get.chezmoi.io)" -- -b "$HOME/.local/bin"
  else
    echo "❌ Neither curl nor wget found. Please install one and re-run."
    exit 1
  fi
  # Ensure current process can find newly installed chezmoi
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
  echo "• chezmoi installed: $(chezmoi --version | head -n1)"
fi

echo "• Initializing chezmoi with local source"
set -x
chezmoi init --source="$SOURCE_DIR"
if [[ "$DRY_RUN" == "1" ]]; then
  # Prefer diff in dry-run to avoid any interactive behavior
  chezmoi diff --source="$SOURCE_DIR" --verbose
else
  chezmoi apply --source="$SOURCE_DIR" --verbose
fi
set +x

if command -v mise >/dev/null 2>&1; then
  echo "• Running 'mise install' (if configured)"
  mise install || true
else
  echo "• 'mise' not found. You can install it later and run 'mise install'."
fi

echo "✅ Bootstrap complete"
