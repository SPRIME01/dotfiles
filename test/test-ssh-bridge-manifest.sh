#!/usr/bin/env bash
# test-ssh-bridge-manifest.sh - Tests manifest resolution logic for npiperelay
set -uo pipefail
echo "[manifest-test] start"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/framework.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed"
  exit 0
fi

tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT
mkdir -p "$tmpd/bin" "$tmpd/mnt/c/ProgramData/chocolatey/bin" "$tmpd/mnt/c/Tools/npiperelay"

# Create fake npiperelay.exe targets
touch "$tmpd/mnt/c/ProgramData/chocolatey/bin/npiperelay.exe"
touch "$tmpd/mnt/c/Tools/npiperelay/npiperelay.exe"

man() { # write manifest json $1->file
  local path="$1"
  shift || true
  printf '{"version":2,%s}\n' "$*" > "$path"
}

# Case 1: Good npiperelay_wsl
m1="$tmpd/manifest1.json"
good_wsl="$tmpd/mnt/c/ProgramData/chocolatey/bin/npiperelay.exe"
man "$m1" "\"npiperelay_wsl\":\"$good_wsl\""

# Case 2: Double slash in path should be normalized
m2="$tmpd/manifest2.json"
bad_wsl="$tmpd/mnt/c//ProgramData//chocolatey/bin//npiperelay.exe"
man "$m2" "\"npiperelay_wsl\":\"$bad_wsl\""

# Case 3: Only Windows path available
m3="$tmpd/manifest3.json"
win_only='C:\\ProgramData\\chocolatey\\bin\\npiperelay.exe'
man "$m3" "\"npiperelay_win\":\"$win_only\""

# Case 4: Truncated/corrupted path value should fail
m4="$tmpd/manifest4.json"
corrupt='C:\\ProgramData\\chocolatey\\bin\\ DEBUGelay.exe'
man "$m4" "\"npiperelay_path\":\"$corrupt\""

# Wire up PATHs for helper resolution
export PATH="$REPO_ROOT/ssh-agent-bridge:$PATH"

run_resolve() {
  ( cd "$REPO_ROOT/ssh-agent-bridge" && bash -c "source ./common.sh && resolve_npiperelay_from_manifest '$1'" )
}

set +e
out1=$(run_resolve "$m1"); c1=$?
out2=$(run_resolve "$m2"); c2=$?
out3=$(run_resolve "$m3"); c3=$?
out4=$(run_resolve "$m4"); c4=$?
set -e
echo "[manifest-test] collected results c1=$c1 c2=$c2 c3=$c3 c4=$c4"

test_assert "Manifest1 resolves OK" "echo $c1" "0"
test_assert_equal "Manifest1 path exact" "$out1" "$good_wsl"

test_assert "Manifest2 normalizes OK" "echo $c2" "0"
test_assert_equal "Manifest2 normalized path" "$out2" "${good_wsl}"

test_assert "Manifest3 converts win->wsl" "echo $c3" "0"
test_assert_equal "Manifest3 converted path" "$out3" "$good_wsl"

test_assert "Manifest4 fails to resolve" "echo $c4" "3"

echo "[manifest-test] before summary"
if test_summary; then
  echo "✅ manifest resolution tests complete"
  exit 0
else
  echo "❌ manifest resolution tests failed"
  exit 1
fi

