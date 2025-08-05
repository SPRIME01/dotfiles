#!/usr/bin/env bash
echo "🔐 Setting up Windows SSH Agent auto-start..."
echo "⚠️  Note: SSH agent is currently disabled in .zshrc due to missing npiperelay"
echo "💡 To enable SSH agent, first install npiperelay via Scoop:"
echo "   scoop install npiperelay"
echo "💡 Then uncomment SSH agent setup in .zshrc"

# Check if we're in WSL
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
    echo "❌ This command is designed for WSL2 environments"
    echo "💡 Run this from WSL2 to configure Windows SSH Agent"
    exit 1
fi

# Check if npiperelay is installed
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' 2>/dev/null)
NPIPERELAY_PATH="/mnt/c/Users/$WIN_USER/scoop/apps/npiperelay/0.1.0/npiperelay.exe"

if [[ ! -x "$NPIPERELAY_PATH" ]]; then
    echo "❌ npiperelay not found at $NPIPERELAY_PATH"
    echo "💡 Install npiperelay first: scoop install npiperelay"
    exit 1
fi

# Check if PowerShell is available
if ! command -v powershell.exe >/dev/null 2>&1; then
    echo "❌ PowerShell not found on Windows"
    exit 1
fi

echo "▶️  Running Windows SSH Agent setup..."
powershell.exe -ExecutionPolicy Bypass -File "$PWD/scripts/setup-ssh-agent-windows-simple.ps1"

echo ""
echo "🎉 Windows SSH Agent setup complete!"
echo "💡 Your SSH keys should now load automatically when you start PowerShell"
echo "💡 To enable in zsh, uncomment SSH agent setup in .zshrc"
