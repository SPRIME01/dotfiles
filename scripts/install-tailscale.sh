#!/usr/bin/env bash
set -euo pipefail

# Install and configure Tailscale on WSL2
# Usage:
#   ./install-tailscale.sh

echo "==> Tailscale Setup"

if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
  echo "❌ This script is intended for WSL2."
  exit 1
fi

# Check if Tailscale is installed
if ! command -v tailscale >/dev/null 2>&1; then
  echo "📦 Tailscale not found. Installing..."
  curl -fsSL https://tailscale.com/install.sh | sh
else
  echo "✅ Tailscale already installed: $(tailscale --version)"
fi

# Check if authenticated
STATUS=$(tailscale status --json 2>/dev/null || echo "{}")
BACKEND_STATE=$(echo "$STATUS" | jq -r '.BackendState // "NeedsLogin"')

if [[ "$BACKEND_STATE" == "Running" ]]; then
  echo "✅ Tailscale is already running and authenticated."
  exit 0
fi

echo "🔄 Configuring Tailscale..."

# Construct tailscale up command
CMD="tailscale up --ssh --advertise-tags=tag:homelab-wsl2"

if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
  echo "🔑 Using TAILSCALE_AUTH_KEY from environment."
  CMD="$CMD --auth-key=$TAILSCALE_AUTH_KEY"
else
  echo "⚠️  TAILSCALE_AUTH_KEY not set. You will need to authenticate interactively."
fi

# Execute
echo "🚀 Running: $CMD"
sudo $CMD

echo "✅ Tailscale setup complete!"
