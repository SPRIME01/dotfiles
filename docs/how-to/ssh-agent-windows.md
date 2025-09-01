# Windows SSH Agent Auto-Start Setup

This document explains how to set up SSH agent to start automatically on Windows and integrate with your dotfiles.

## Method 1: Windows OpenSSH Authentication Agent Service (Recommended)

Windows 10/11 includes an OpenSSH Authentication Agent service that can automatically start SSH agent.

### Enable and Configure the Service

1. **Enable the service** (run as Administrator):
   ```powershell
   # Enable the service
   Set-Service ssh-agent -StartupType Automatic

   # Start the service now
   Start-Service ssh-agent

   # Verify it's running
   Get-Service ssh-agent
   ```

2. **Add keys automatically** by adding this to your PowerShell profile:
   ```powershell
   # Add SSH keys to Windows SSH Agent on startup
   if (Get-Service ssh-agent -ErrorAction SilentlyContinue | Where-Object Status -eq "Running") {
       ssh-add "$env:USERPROFILE\.ssh\id_ed25519" 2>$null
   }
   ```

### PowerShell Profile Integration

Your dotfiles can automatically configure this. The setup scripts will:
- Enable the SSH agent service
- Add key loading to your PowerShell profile
- Configure git to use the Windows SSH agent

## Method 2: Pageant (PuTTY SSH Agent)

If you prefer Pageant (useful for PuTTY integration):

1. **Install PuTTY suite** (includes Pageant)
2. **Auto-start Pageant** by adding to Windows startup:
   - Add shortcut to: `shell:startup`
   - Target: `"C:\Program Files\PuTTY\pageant.exe" "C:\Users\%USERNAME%\.ssh\id_ed25519.ppk"`

## Method 3: Git Bash SSH Agent

If using Git for Windows:

1. **Add to your `.bashrc` or `.bash_profile`**:
   ```bash
   # Start SSH agent if not running
   if ! pgrep -x "ssh-agent" > /dev/null; then
       eval "$(ssh-agent -s)"
       ssh-add ~/.ssh/id_ed25519
   fi
   ```

## Integration with Dotfiles

Your dotfiles setup will automatically:
1. Detect available SSH agent options
2. Configure the appropriate method
3. Add key loading to shell profiles
4. Set up git integration

Use `just setup-ssh-agent` to configure automatically.

## Troubleshooting

### SSH Agent Not Starting
```powershell
# Check service status
Get-Service ssh-agent

# Manual start
Start-Service ssh-agent

# Check if keys are loaded
ssh-add -l
```

### Keys Not Loading
```powershell
# Add key manually
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"

# Check git configuration
git config --get core.sshCommand
```
