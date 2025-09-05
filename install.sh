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
  INSTALLER_URL="https://get.chezmoi.io"
  TMP_LOG="$(mktemp /tmp/chezmoi-install.XXXXXX.log)"
  echo "  → installer log: $TMP_LOG"

  if command -v curl >/dev/null 2>&1; then
    if ! sh -c "$(curl -fsLS "$INSTALLER_URL")" -- -b "$HOME/.local/bin" 2>&1 | tee "$TMP_LOG"; then
      echo "❌ chezmoi installer (curl) failed. Installer output saved to: $TMP_LOG"
      echo "----- last 200 lines of installer log -----"
      tail -n 200 "$TMP_LOG" || true
      echo "Please inspect the full log and re-run the script. Exiting."
      exit 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! sh -c "$(wget -qO- "$INSTALLER_URL")" -- -b "$HOME/.local/bin" 2>&1 | tee "$TMP_LOG"; then
      echo "❌ chezmoi installer (wget) failed. Installer output saved to: $TMP_LOG"
      echo "----- last 200 lines of installer log -----"
      tail -n 200 "$TMP_LOG" || true
      echo "Please inspect the full log and re-run the script. Exiting."
      exit 1
    fi
  else
    echo "❌ Neither curl nor wget found. Please install one and re-run."
    exit 1
  fi

  # Ensure current process can find newly installed chezmoi
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac

  if ! command -v chezmoi >/dev/null 2>&1; then
    echo "❌ chezmoi not found after installation. Check installer log: $TMP_LOG"
    exit 1
  fi

  echo "• chezmoi installed: $(chezmoi --version | head -n1)"
  rm -f "$TMP_LOG"
fi

echo "• Initializing chezmoi with local source"
set -x
chezmoi init --source="$SOURCE_DIR"
if [[ $? -ne 0 ]]; then
  echo "ERROR: 'chezmoi init' failed. Please check your source directory and try again."
  echo "You can run 'chezmoi init --source=\"$SOURCE_DIR\"' manually for more details."
  exit 1
fi
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
