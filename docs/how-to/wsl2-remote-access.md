# WSL2 Remote Access Setup Guide

This guide shows how to access your WSL2 environment from another computer on your local network using VS Code Remote-SSH.

## Prerequisites
- ✅ SSH keys already shared between computers (passwordless SSH)
- ✅ WSL2 running on the host computer
- ✅ VS Code with Remote-SSH extension on client computer

## Method 1: SSH Directly to WSL2 (Recommended for Development)

### Step 1: Enable SSH Server in WSL2

1. **Install OpenSSH Server in WSL2:**
   ```bash
   # Update packages
   sudo apt update

   # Install OpenSSH server
   sudo apt install openssh-server -y
   ```

2. **Configure SSH Server:**
   ```bash
   # Edit SSH config
   sudo nano /etc/ssh/sshd_config

   # Ensure these settings:
   Port 2222
   PasswordAuthentication no
   PubkeyAuthentication yes
   PermitRootLogin no
   ```

3. **Start SSH Service:**
   ```bash
   # Start SSH service
   sudo service ssh start

   # Enable auto-start (optional)
   sudo systemctl enable ssh
   ```

4. **Add Your Public Key:**
   ```bash
   # Create .ssh directory if it doesn't exist
   mkdir -p ~/.ssh
   chmod 700 ~/.ssh

   # Add your public key from the remote computer
   echo "your-public-key-here" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

### Step 2: Configure Windows Firewall and Port Forwarding

1. **Allow WSL2 SSH Port through Windows Firewall:**
   ```powershell
   # Run as Administrator
   New-NetFirewallRule -DisplayName "WSL2 SSH" -Direction Inbound -Protocol TCP -LocalPort 2222 -Action Allow
   ```

2. **Set up Port Forwarding (PowerShell as Admin):**
   ```powershell
   # Get WSL2 IP address
   $wslIP = (wsl hostname -I).Trim()

   # Create port proxy
   netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=2222 connectaddress=$wslIP

   # Verify the rule
   netsh interface portproxy show v4tov4
   ```

### Step 3: Configure VS Code Remote-SSH

1. **On the client computer, edit SSH config:**
   ```bash
   # Edit ~/.ssh/config
   Host wsl-development
       HostName your-windows-computer-ip
       Port 2222
       User your-wsl-username
       IdentityFile ~/.ssh/id_ed25519
       StrictHostKeyChecking no
   ```

2. **Connect via VS Code:**
   - Open VS Code
   - Press `Ctrl+Shift+P`
   - Type "Remote-SSH: Connect to Host"
   - Select "wsl-development"

## Method 2: SSH to Windows then WSL2 (Alternative)

### Step 1: Enable Windows SSH Server

1. **Install OpenSSH Server on Windows:**
   ```powershell
   # Install OpenSSH Server (Windows 10/11)
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

   # Start and enable the service
   Start-Service sshd
   Set-Service -Name sshd -StartupType 'Automatic'
   ```

2. **Configure Windows SSH:**
   ```powershell
   # Allow through firewall
   New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
   ```

### Step 2: Configure VS Code with Jump Host

```bash
# ~/.ssh/config on client computer
Host windows-host
    HostName your-windows-computer-ip
    User your-windows-username
    IdentityFile ~/.ssh/id_ed25519

Host wsl-via-windows
    HostName localhost
    Port 22
    User your-wsl-username
    ProxyJump windows-host
    ProxyCommand ssh -W %h:%p windows-host -t "wsl.exe"
    IdentityFile ~/.ssh/id_ed25519
```

## Method 3: Using WSL2 IP Directly (Advanced)

### Automated Script for Dynamic IP

```bash
#!/bin/bash
# get-wsl-ip.sh
WSL_IP=$(ip route show | grep -i default | awk '{ print $3}')
echo "WSL2 IP: $WSL_IP"
```

## Troubleshooting

### Common Issues

1. **Cannot connect to WSL2:**
   ```bash
   # Check if SSH is running in WSL2
   sudo service ssh status

   # Check if port is listening
   sudo netstat -tlnp | grep :2222
   ```

2. **Port forwarding not working:**
   ```powershell
   # Remove existing rules
   netsh interface portproxy delete v4tov4 listenport=2222 listenaddress=0.0.0.0

   # Re-add with current WSL IP
   $wslIP = (wsl hostname -I).Trim()
   netsh interface portproxy add v4tov4 listenport=2222 listenaddress=0.0.0.0 connectport=2222 connectaddress=$wslIP
   ```

3. **Firewall blocking connection:**
   ```powershell
   # Check Windows Firewall rules
   Get-NetFirewallRule -DisplayName "*WSL*" | Select-Object DisplayName, Enabled, Direction
   ```

### Network Discovery

```bash
# Find your Windows computer IP
ip route show default

# Test connection from client
ssh -p 2222 username@windows-computer-ip

# Test from WSL2
curl -I http://httpbin.org/ip
```

## Security Considerations

- ✅ Use key-based authentication only
- ✅ Disable password authentication
- ✅ Use non-standard ports
- ✅ Consider VPN for additional security
- ✅ Regularly update SSH keys
- ⚠️ Be cautious with port forwarding rules
- ⚠️ Monitor SSH access logs

## Auto-Start SSH Service

Add to your WSL2 startup (in `.bashrc` or `.zshrc`):
```bash
# Auto-start SSH service if not running
if ! pgrep -x "sshd" > /dev/null; then
    sudo service ssh start
fi
```
