# SSH Agent Windows Auto-Start - Quick Reference

## For WSL Users (Recommended)
```bash
# Set up everything automatically
just setup-ssh-agent-windows

# Or run the setup wizard (includes SSH agent setup)
just setup
```

## For Windows Users
1. **Run from Windows Explorer:**
   - Navigate to your dotfiles `scripts` folder
   - Double-click `setup-ssh-agent-windows.bat`

2. **Run from PowerShell:**
   ```powershell
   # Navigate to your dotfiles directory
   cd C:\path\to\your\dotfiles
   .\scripts\setup-ssh-agent-windows.ps1
   ```

## What It Does
✅ Enables Windows SSH Agent service for automatic startup  
✅ Adds your SSH key to the agent  
✅ Configures PowerShell to auto-load keys on startup  
✅ Tests GitHub SSH connection  

## Manual Commands (if needed)
```powershell
# Enable SSH Agent service (requires Admin)
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent

# Add SSH key
ssh-add "$env:USERPROFILE\.ssh\id_ed25519"

# Test connection
ssh -T git@github.com
```

## Troubleshooting
- **Service not starting:** Run PowerShell as Administrator
- **Keys not loading:** Check if your SSH key exists at `%USERPROFILE%\.ssh\id_ed25519`
- **GitHub connection fails:** Verify your SSH key is added to GitHub

## Integration with Dotfiles
This setup integrates with your dotfiles by:
- Using your existing SSH keys
- Working with your PowerShell profile configuration
- Supporting your WSL2-Windows development workflow
