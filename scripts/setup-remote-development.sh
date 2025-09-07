#!/usr/bin/env bash
# Complete WSL2 Remote Development Setup
# This script sets up everything needed for remote VS Code access to WSL2

set -euo pipefail

echo "🚀 WSL2 Remote Development Complete Setup"
echo "=========================================="
echo ""

# Check if we're in WSL2
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
	echo "❌ This script must be run from WSL2"
	exit 1
fi

echo "This script will:"
echo "✅ Set up SSH server in WSL2"
echo "✅ Configure Windows firewall and port forwarding"
echo "✅ Generate client SSH configuration"
echo "✅ Set up auto-start for SSH services"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	exit 0
fi

echo "📋 Step 1: Setting up WSL2 SSH server..."
echo "======================================="
if ./scripts/setup-wsl2-remote-access.sh; then
	echo "✅ WSL2 SSH server setup complete"
else
	echo "❌ WSL2 SSH server setup failed"
	exit 1
fi

echo ""
echo "📋 Step 2: Configuring Windows..."
echo "================================="
echo "⚠️  The next step requires Administrator privileges on Windows"
echo "   A PowerShell window will open - please approve any UAC prompts"
echo ""

read -p "Ready to configure Windows? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
	WIN_PATH=$(wslpath -w "$PWD/scripts/setup-wsl2-remote-windows.ps1")
	if powershell.exe -ExecutionPolicy Bypass -File "$WIN_PATH"; then
		echo "✅ Windows configuration complete"
	else
		echo "⚠️  Windows configuration may have failed"
		echo "💡 You can run it manually later with: just setup-wsl2-remote-windows"
	fi
else
	echo "⚠️  Skipping Windows configuration"
	echo "💡 Run it later with: just setup-wsl2-remote-windows"
fi

echo ""
echo "📋 Step 3: Testing setup..."
echo "==========================="

# Get network info
WSL_IP=$(hostname -I | awk '{print $1}')
WINDOWS_IP=$(ip route show default | awk '{print $3}')
COMPUTER_NAME=$(cmd.exe /c "echo %COMPUTERNAME%" 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]')

echo "🌐 Network Information:"
echo "   Computer: $COMPUTER_NAME"
echo "   Windows IP: $WINDOWS_IP"
echo "   WSL2 IP: $WSL_IP"
echo "   SSH Port: 2222"

# Test SSH service
if pgrep -x "sshd" >/dev/null; then
	echo "✅ SSH daemon is running in WSL2"
else
	echo "❌ SSH daemon is not running"
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "📝 To connect from another computer:"
echo ""
echo "1. Add this to the client's ~/.ssh/config:"
echo ""
echo "Host wsl-$COMPUTER_NAME"
echo "    HostName $WINDOWS_IP"
echo "    Port 2222"
echo "    User $USER"
echo "    IdentityFile ~/.ssh/id_ed25519"
echo "    StrictHostKeyChecking no"
echo "    ServerAliveInterval 60"
echo ""
echo "2. Test connection:"
echo "   ssh wsl-$COMPUTER_NAME"
echo ""
echo "3. For VS Code:"
echo "   - Install Remote-SSH extension"
echo "   - Connect to host: wsl-$COMPUTER_NAME"
echo ""
echo "🔧 Useful commands:"
echo "   just setup-wsl2-remote          # Setup WSL2 side only"
echo "   just setup-wsl2-remote-windows  # Setup Windows side only"
echo "   just setup-wsl2-complete        # Complete setup"
echo ""
echo "📚 Documentation: docs/wsl2-remote-access.md"
