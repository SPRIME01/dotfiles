#!/usr/bin/env bash
# Setup WSL2 SSH Server for Remote Access

set -euo pipefail

echo "🌐 Setting up WSL2 for remote access via SSH..."

# Check if we're in WSL2
if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
    echo "❌ This script must be run from WSL2"
    exit 1
fi

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local reply
    
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -r -p "$prompt" reply
    reply="${reply:-$default}"
    
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

# Step 1: Install OpenSSH Server
echo "📋 Step 1: Installing OpenSSH Server..."
if ! command -v sshd >/dev/null 2>&1; then
    echo "Installing OpenSSH server..."
    sudo apt update
    sudo apt install -y openssh-server
    echo "✅ OpenSSH server installed"
else
    echo "✅ OpenSSH server already installed"
fi

# Step 2: Configure SSH
echo "📋 Step 2: Configuring SSH Server..."

SSH_CONFIG="/etc/ssh/sshd_config"
SSH_PORT="2222"

# Backup original config
if [[ ! -f "${SSH_CONFIG}.backup" ]]; then
    sudo cp "$SSH_CONFIG" "${SSH_CONFIG}.backup"
    echo "✅ Created backup of SSH config"
fi

# Configure SSH settings
sudo tee "$SSH_CONFIG" > /dev/null << EOF
# WSL2 SSH Configuration
Port $SSH_PORT
Protocol 2

# Authentication
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Security
PermitRootLogin no
MaxAuthTries 3
MaxSessions 10

# Logging
SyslogFacility AUTH
LogLevel INFO

# Connection
ClientAliveInterval 300
ClientAliveCountMax 2

# Subsystems
Subsystem sftp /usr/lib/openssh/sftp-server

# Allow specific users (add your username)
AllowUsers $USER
EOF

echo "✅ SSH server configured (Port: $SSH_PORT)"

# Step 3: Set up SSH keys
echo "📋 Step 3: Setting up SSH keys..."

SSH_DIR="$HOME/.ssh"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$AUTHORIZED_KEYS" ]]; then
    touch "$AUTHORIZED_KEYS"
fi
chmod 600 "$AUTHORIZED_KEYS"

echo "✅ SSH directory configured"
echo "📝 Add your public keys to: $AUTHORIZED_KEYS"

# Step 4: Start SSH service
echo "📋 Step 4: Starting SSH service..."

if sudo service ssh start; then
    echo "✅ SSH service started"
else
    echo "⚠️  SSH service may already be running"
fi

# Check if service is running
if pgrep -x "sshd" > /dev/null; then
    echo "✅ SSH daemon is running"
    
    # Show listening ports
    echo "📡 SSH is listening on:"
    sudo netstat -tlnp | grep sshd | grep ":$SSH_PORT"
else
    echo "❌ SSH daemon is not running"
    exit 1
fi

# Step 5: Get WSL2 IP address
echo "📋 Step 5: Network Information..."

WSL_IP=$(hostname -I | awk '{print $1}')
WINDOWS_IP=$(ip route show default | awk '{print $3}')

echo "🌐 Network Information:"
echo "   WSL2 IP: $WSL_IP"
echo "   Windows IP: $WINDOWS_IP"
echo "   SSH Port: $SSH_PORT"

# Step 6: Generate Windows PowerShell commands
echo "📋 Step 6: Windows Configuration Commands..."

echo ""
echo "🪟 Run these commands on Windows (as Administrator):"
echo ""
echo "# Allow WSL2 SSH through Windows Firewall:"
echo "New-NetFirewallRule -DisplayName 'WSL2 SSH' -Direction Inbound -Protocol TCP -LocalPort $SSH_PORT -Action Allow"
echo ""
echo "# Set up port forwarding:"
echo "netsh interface portproxy add v4tov4 listenport=$SSH_PORT listenaddress=0.0.0.0 connectport=$SSH_PORT connectaddress=$WSL_IP"
echo ""
echo "# Verify port forwarding:"
echo "netsh interface portproxy show v4tov4"
echo ""

# Step 7: Generate SSH config for client
echo "📋 Step 7: Client SSH Configuration..."

echo "📝 Add this to your client's ~/.ssh/config:"
echo ""
echo "Host wsl-$HOSTNAME"
echo "    HostName $WINDOWS_IP"
echo "    Port $SSH_PORT"
echo "    User $USER"
echo "    IdentityFile ~/.ssh/id_ed25519"
echo "    StrictHostKeyChecking no"
echo "    ServerAliveInterval 60"
echo ""

# Step 8: Auto-start configuration
echo "📋 Step 8: Auto-start Configuration..."

if prompt_yes_no "Add SSH auto-start to shell profile?"; then
    SHELL_PROFILE=""
    if [[ -n "${ZSH_VERSION:-}" ]] && [[ -f "$HOME/.zshrc" ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ -n "${BASH_VERSION:-}" ]] && [[ -f "$HOME/.bashrc" ]]; then
        SHELL_PROFILE="$HOME/.bashrc"
    fi
    
    if [[ -n "$SHELL_PROFILE" ]]; then
        SSH_AUTOSTART='
# Auto-start SSH service for remote access
if ! pgrep -x "sshd" > /dev/null; then
    if command -v sshd >/dev/null 2>&1; then
        sudo service ssh start >/dev/null 2>&1
    fi
fi'
        
        if ! grep -q "Auto-start SSH service" "$SHELL_PROFILE"; then
            echo "$SSH_AUTOSTART" >> "$SHELL_PROFILE"
            echo "✅ Added SSH auto-start to $SHELL_PROFILE"
        else
            echo "✅ SSH auto-start already configured"
        fi
    fi
fi

echo ""
echo "🎉 WSL2 Remote Access Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Run the Windows PowerShell commands above (as Administrator)"
echo "2. Add your public key to: $AUTHORIZED_KEYS"
echo "3. Configure SSH client as shown above"
echo "4. Test connection: ssh -p $SSH_PORT $USER@$WINDOWS_IP"
echo ""
echo "💡 For VS Code Remote-SSH, use the host name 'wsl-$HOSTNAME'"
