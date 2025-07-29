#!/usr/bin/env bash
set -euo pipefail

# Unit tests for the Bash/Zsh environment loader (load_env.sh) and
# .shell_common.sh integration.  This script is intended to be run via
# scripts/run-tests.sh, which sets DOTFILES_ROOT automatically.

# Determine repository root
if [[ -z "${DOTFILES_ROOT:-}" ]]; then
  echo "DOTFILES_ROOT is not set; please run via run-tests.sh" >&2
  exit 1
fi

# Create a temporary directory and a sample .env file
tmp_dir="$(mktemp -d)"
sample_env="$tmp_dir/sample.env"
cat > "$sample_env" <<'EOF'
FOO=bar
BAR="quoted value"
EMPTY=
# Comment line should be ignored
EOF

# Source load_env.sh and call load_env_file on the sample file
source "$DOTFILES_ROOT/scripts/load_env.sh"

# Unset variables first to avoid false positives
unset FOO BAR EMPTY || true

load_env_file "$sample_env"

if [[ "$FOO" != "bar" ]]; then
  echo "Test failed: FOO expected 'bar' but got '${FOO:-}'" >&2
  exit 1
fi

if [[ "$BAR" != "quoted value" ]]; then
  echo "Test failed: BAR expected 'quoted value' but got '${BAR:-}'" >&2
  exit 1
fi

# EMPTY should be set to an empty string
if [[ -z "${EMPTY+x}" ]]; then
  echo "Test failed: EMPTY should be defined" >&2
  exit 1
fi

echo "✅ load_env_file successfully parsed simple .env file"

# Test .shell_common.sh overrides defaults when .env defines PROJECTS_ROOT
sample_env2="$tmp_dir/sample2.env"
cat > "$sample_env2" <<EOF
PROJECTS_ROOT="$tmp_dir/projects"
EOF

unset PROJECTS_ROOT || true
source "$DOTFILES_ROOT/.shell_common.sh" >/dev/null 2>&1
if [[ "$PROJECTS_ROOT" != "$HOME/Projects" ]]; then
  echo "Test failed: default PROJECTS_ROOT should be \$HOME/Projects" >&2
  exit 1
fi

# Source .shell_common.sh with custom .env loaded via load_env_file
source "$DOTFILES_ROOT/scripts/load_env.sh"
load_env_file "$sample_env2"

source "$DOTFILES_ROOT/.shell_common.sh" >/dev/null 2>&1
if [[ "$PROJECTS_ROOT" != "$tmp_dir/projects" ]]; then
  echo "Test failed: PROJECTS_ROOT override did not take effect" >&2
  exit 1
fi

echo "✅ .shell_common.sh correctly applied PROJECTS_ROOT override"

# Clean up
rm -rf "$tmp_dir"