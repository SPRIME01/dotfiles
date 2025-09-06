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

  # Ensure installer log is removed on success, but preserved on failure for debugging.
  KEEP_TMP_LOG=0
  cleanup_installer_log() {
    if [[ "$KEEP_TMP_LOG" -eq 0 ]]; then
      rm -f "$TMP_LOG"
    else
      echo "• Installer log preserved at: $TMP_LOG"
    fi
  }
  trap cleanup_installer_log EXIT

  if command -v curl >/dev/null 2>&1; then
    # Run the remote installer while capturing its output; preserve exit status.
    if ! curl -fsLS "$INSTALLER_URL" 2>&1 | tee "$TMP_LOG" | sh -s -- -b "$HOME/.local/bin"; then
      KEEP_TMP_LOG=1
      echo "❌ chezmoi installer (curl) failed. Installer output saved to: $TMP_LOG"
      echo "----- last 200 lines of installer log -----"
      tail -n 200 "$TMP_LOG" || true
      echo "You can retry manually with:"
      echo "  curl -fsSL \"$INSTALLER_URL\" | sh -s -- -b \"\$HOME/.local/bin\""
      exit 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    if ! wget -qO- "$INSTALLER_URL" 2>&1 | tee "$TMP_LOG" | sh -s -- -b "$HOME/.local/bin"; then
      KEEP_TMP_LOG=1
      echo "❌ chezmoi installer (wget) failed. Installer output saved to: $TMP_LOG"
      echo "----- last 200 lines of installer log -----"
      tail -n 200 "$TMP_LOG" || true
      echo "You can retry manually with:"
      echo "  wget -qO- \"$INSTALLER_URL\" | sh -s -- -b \"\$HOME/.local/bin\""
      exit 1
    fi
  else
    KEEP_TMP_LOG=1
    echo "❌ Neither curl nor wget found. Please install one and re-run."
    exit 1
  fi

  # Make the freshly installed binary discoverable in this session
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v chezmoi >/dev/null 2>&1; then
    KEEP_TMP_LOG=1
    echo "❌ chezmoi not found after installation. Check installer log: $TMP_LOG"
    exit 1
  fi

  echo "• chezmoi installed: $(chezmoi --version | head -n1)"
  # cleanup_installer_log will run on EXIT; TMP_LOG removed unless KEEP_TMP_LOG was set.
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
  chezmoi diff --source="$SOURCE_DIR" --verbose || true
else
  chezmoi apply --source="$SOURCE_DIR" --verbose
fi
set +x

# Ensure Git uses the global ignore file installed by chezmoi
if command -v git >/dev/null 2>&1; then
  GITIGNORE_GLOBAL_PATH="$HOME/.gitignore_global"
  CURRENT_EXCLUDESFILE="$(git config --global --get core.excludesfile 2>/dev/null || true)"

  if [[ -z "$CURRENT_EXCLUDESFILE" ]]; then
    echo "• Configuring Git global excludesfile → $GITIGNORE_GLOBAL_PATH"
    git config --global core.excludesfile "$GITIGNORE_GLOBAL_PATH" || true
  elif [[ "$CURRENT_EXCLUDESFILE" != "$GITIGNORE_GLOBAL_PATH" ]]; then
    echo "⚠️  Git core.excludesfile is set to: $CURRENT_EXCLUDESFILE"
    echo "   Leaving as-is. To use this repo's global ignore, run:"
    echo "   git config --global core.excludesfile \"$GITIGNORE_GLOBAL_PATH\""
  else
    echo "• Git global excludesfile already set"
  fi
else
  echo "• Git not found; skipping global excludesfile configuration"
fi

if command -v mise >/dev/null 2>&1; then
  echo "• Running 'mise install' (if configured)"
  mise install || true
else
  echo "• 'mise' not found. You can install it later and run 'mise install'."
fi

echo "✅ Bootstrap complete"
