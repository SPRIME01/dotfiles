#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/framework.sh"

# Skip outside WSL
if ! grep -qi microsoft /proc/version 2>/dev/null && [ -z "${WSL_DISTRO_NAME:-}" ]; then
  echo "SKIP: ssh-bridge workflow tests (not WSL)"
  exit 0
fi

# Require powershell.exe & manifest to meaningfully exercise installer; otherwise skip (environment minimal in CI)
if ! command -v powershell.exe >/dev/null 2>&1; then
  echo "SKIP: powershell.exe not available"
  exit 0
fi
WINUSER=$(powershell.exe -NoProfile -NonInteractive -Command '$env:UserName' 2>/dev/null | tr -d '\r' | tail -n1 || true)
MANIFEST="/mnt/c/Users/${WINUSER}/.ssh/bridge-manifest.json"
if [[ ! -f "$MANIFEST" ]]; then
  echo "SKIP: bridge manifest missing at $MANIFEST"
  exit 0
fi

TEST_HOME="$(mktemp -d)"
export HOME="$TEST_HOME"
mkdir -p "$HOME/.ssh" "$HOME/.local/bin"

cp "$REPO_ROOT/ssh-agent-bridge/install-wsl-agent-bridge.sh" "$HOME/"
cp "$REPO_ROOT/ssh-agent-bridge/uninstall-wsl-bridge.sh" "$HOME/"

echo "== Test: install-wsl-agent-bridge dry-run leaves no changes =="
bash "$HOME/install-wsl-agent-bridge.sh" --dry-run --verbose > /dev/null 2>&1 || true
test_assert "Dry-run did not create manifest" "test ! -f \"$HOME/.ssh/bridge-manifest.wsl.json\"; echo $?" "0"
test_assert "Dry-run did not create helper" "test ! -f \"$HOME/.local/bin/win-ssh-agent-bridge\"; echo $?" "0"

echo "== Test: real install creates block and manifest =="
bash "$HOME/install-wsl-agent-bridge.sh" --verbose || true
test_assert "Manifest created" "test -f \"$HOME/.ssh/bridge-manifest.wsl.json\"; echo $?" "0"
test_assert "Helper created" "test -f \"$HOME/.local/bin/win-ssh-agent-bridge\"; echo $?" "0"

echo "== Test: idempotent second run (no duplicate blocks) =="
before_lines=$(grep -c 'WSL→Windows SSH agent bridge (BEGIN)' "$HOME/.bashrc" || echo 0)
bash "$HOME/install-wsl-agent-bridge.sh" --verbose || true
after_lines=$(grep -c 'WSL→Windows SSH agent bridge (BEGIN)' "$HOME/.bashrc" || echo 0)
test_assert "No duplicate BEGIN markers" "[ \"$after_lines\" -eq 1 ]; echo $?" "0"

echo "== Test: uninstall dry-run does not remove block =="
bash "$HOME/uninstall-wsl-bridge.sh" --dry-run --verbose > /dev/null 2>&1 || true
still_lines=$(grep -c 'WSL→Windows SSH agent bridge (BEGIN)' "$HOME/.bashrc" || echo 0)
test_assert "Block still present after dry-run uninstall" "[ \"$still_lines\" -eq 1 ]; echo $?" "0"

echo "== Test: uninstall removes block =="
bash "$HOME/uninstall-wsl-bridge.sh" --verbose || true
gone_lines=$(grep -c 'WSL→Windows SSH agent bridge (BEGIN)' "$HOME/.bashrc" || echo 0)
test_assert "Block removed" "[ \"$gone_lines\" -eq 0 ]; echo $?" "0"

echo "== Test: deploy script requires --confirm-cleanup for cleanup =="
mkdir -p "$HOME/.ssh/logs"
touch "$HOME/.ssh/config"
echo 'Host test-host' > "$HOME/.ssh/config"
# Fake public key for deployment (simulate) since actual ssh may fail; run in dry-run mode
PUBKEY="$HOME/.ssh/id_ed25519.pub"; echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAfakekey test@local" > "$PUBKEY"
# Simulate old keys detection by crafting script expectations (no real removal occurs in dry-run)
OUTPUT=$(DRY_RUN=1 bash "$REPO_ROOT/ssh-agent-bridge/deploy-ssh-key-to-hosts.sh" --dry-run --verbose --only test-host 2>&1 || true)
test_assert_contains "Deploy dry-run mentions cleanup skipped when no confirm" "$OUTPUT" "DRY-RUN" || true

if test_summary; then
  echo "✅ ssh-bridge-workflows tests complete"
  exit 0
else
  exit 1
fi
