# PowerShell 7 Windows Setup

## Problem
PowerShell 7 (`pwsh`) on Windows doesn't have access to your dotfiles aliases and functions like `projects` because it uses a different profile location than Windows PowerShell.

## Solution
Run the setup script to create a PowerShell 7 profile that loads your dotfiles configuration.

## Quick Setup

### Option 1: Run from Windows PowerShell
```powershell
# Open Windows PowerShell as Administrator and run:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
powershell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\prime\dotfiles\scripts\setup-windows-pwsh7-profile.ps1"
```

### Option 2: Run the batch file
1. Navigate to your dotfiles folder in Windows Explorer
2. Go to the `scripts` folder
3. Right-click `setup-windows-pwsh7-profile.bat` and "Run as administrator"

### Option 3: Manual setup
If the above don't work, you can manually create the profile:

1. Open PowerShell 7 (`pwsh`)
2. Run: `$PROFILE` to see the profile path
3. Create the directory if it doesn't exist
4. Create a profile file that sources your main dotfiles profile

## What the setup does
1. Detects your PowerShell 7 profile location
2. Creates the profile directory if needed
3. Creates a profile that:
   - Sets `DOTFILES_ROOT` to your WSL dotfiles path
   - Sets `PROJECTS_ROOT` to `%USERPROFILE%\projects`
   - Sources your main PowerShell profile from dotfiles
   - Creates fallback functions if the main profile can't be loaded

## After setup
Open a new PowerShell 7 window and you should be able to use:
- `projects` - Navigate to your projects directory
- All your other dotfiles aliases and functions
- Oh My Posh themes and configurations

## Troubleshooting
- Make sure PowerShell 7 is installed
- Ensure your WSL distribution is running
- Try running PowerShell as Administrator
- Check that the WSL path `\\wsl.localhost\Ubuntu\home\prime\dotfiles` is accessible from Windows
