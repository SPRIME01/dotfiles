#!/usr/bin/env bash
set -euo pipefail

# Minimal helper to run Vault Agent with a file sink for direnv
#
# Env vars:
#   VAULT_ADDR           - Vault address (e.g., https://vault.example.com)
#   VAULT_ROLE           - Auth role (e.g., dev-shell) for OIDC/AppRole/etc.
#   VAULT_AUTH_METHOD    - Auth method (default: oidc). Examples: oidc, approle
#   VAULT_SINK_PATH      - Where to write env file (default: $HOME/.cache/vault/dotfiles.env)
#   VAULT_AGENT_LOG      - Log level (default: info)
#   VAULT_NAMESPACE      - Optional namespace
#
# Notes:
# - Creates the parent directory for VAULT_SINK_PATH if needed (0700)
# - Uses a generated config with absolute paths (no ~ expansion in HCL)
# - Stops on Ctrl+C

VAULT_ADDR=${VAULT_ADDR:-}
VAULT_ROLE=${VAULT_ROLE:-dev-shell}
VAULT_AUTH_METHOD=${VAULT_AUTH_METHOD:-oidc}
VAULT_SINK_PATH=${VAULT_SINK_PATH:-"$HOME/.cache/vault/dotfiles.env"}
VAULT_AGENT_LOG=${VAULT_AGENT_LOG:-info}
VAULT_NAMESPACE=${VAULT_NAMESPACE:-}

if [[ -z "$VAULT_ADDR" ]]; then
  echo "❌ VAULT_ADDR is required (e.g., https://vault.example.com)" >&2
  exit 1
fi

# Resolve absolute sink path and ensure directory exists with strict perms
SINK_PATH=$(python3 - <<EOF
import os,sys
print(os.path.abspath(os.path.expanduser(os.environ.get('VAULT_SINK_PATH', '$HOME/.cache/vault/dotfiles.env'))))
EOF
)
SINK_DIR=$(dirname "$SINK_PATH")
mkdir -p "$SINK_DIR"
chmod 700 "$SINK_DIR" || true

TMP_CONFIG=$(mktemp)
cleanup() { rm -f "$TMP_CONFIG"; }
trap cleanup EXIT INT TERM

{
  echo "auto_auth {"
  echo "  method \"$VAULT_AUTH_METHOD\" {"
  echo "    mount_path = \"auth/$VAULT_AUTH_METHOD\""
  echo "    config = { role = \"$VAULT_ROLE\" }"
  echo "  }"
  echo "  sink \"file\" {"
  echo "    config = { path = \"$SINK_PATH\", format = \"env\" }"
  echo "  }"
  echo "}"
  echo "vault { address = \"$VAULT_ADDR\" }"
  echo "log_level = \"$VAULT_AGENT_LOG\""
  if [[ -n "$VAULT_NAMESPACE" ]]; then
    echo "namespace = \"$VAULT_NAMESPACE\""
  fi
} > "$TMP_CONFIG"

echo "🟢 Starting Vault Agent with sink: $SINK_PATH"
echo "ℹ️  Config: $TMP_CONFIG"
echo "ℹ️  Addr:   $VAULT_ADDR  Role: $VAULT_ROLE  Method: $VAULT_AUTH_METHOD"

exec vault agent -config="$TMP_CONFIG"

