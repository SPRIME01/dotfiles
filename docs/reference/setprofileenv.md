I’ll show the cleanest ways to set DOTFILES_ROOT so PowerShell and other tools can find your repo from Windows and WSL.

## What value to use
- Windows path to a local clone: %USERPROFILE%\dotfiles
- Or UNC path to your WSL clone (preferred for one source of truth):
  \\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles
  Replace Ubuntu-24.04 with your distro name (wsl.exe -l -v).

## Quick (current session only)
- PowerShell (Windows):
  ```powershell
  $env:DOTFILES_ROOT = '\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles'
  ```
- CMD:
  ```cmd
  set DOTFILES_ROOT=\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles
  ```

## Persistent (user environment)
- PowerShell (recommended):
  ```powershell
  [Environment]::SetEnvironmentVariable(
    'DOTFILES_ROOT',
    '\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles',
    'User'
  )
  ```
  Open a new terminal to pick it up. Check with:
  ```powershell
  $env:DOTFILES_ROOT
  Test-Path (Join-Path $env:DOTFILES_ROOT 'PowerShell\Microsoft.PowerShell_profile.ps1')
  ```
- CMD:
  ```cmd
  setx DOTFILES_ROOT \\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles
  ```

## Machine-wide (optional, admin)
```powershell
Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile -Command `[Environment]::SetEnvironmentVariable('DOTFILES_ROOT','\\wsl.localhost\Ubuntu-24.04\home\sprime01\dotfiles','Machine')`"
```

## WSL/Linux shell
If you need it inside WSL too:
```bash
echo 'export DOTFILES_ROOT="$HOME/dotfiles"' >> ~/.zshrc
source ~/.zshrc
```

## Notes
- Your script setup-windows-pwsh7-profile.ps1 already sets $env:DOTFILES_ROOT each pwsh session; use the persistent methods above if other apps (e.g., VS Code, CMD) need it too.
- Prefer the UNC path if your canonical repo is in WSL; otherwise clone to %USERPROFILE%\dotfiles and use that path.
