# Manage Windows Profile from WSL

Use these commands to preview and apply Windows-side changes (for example, your PowerShell profile) from WSL.
Prerequisites
- WSL access to Windows (`powershell.exe` available from WSL)
- chezmoi installed in WSL
- This repo is your chezmoi source (default `~/dotfiles`)

Quick Recipes (recommended)
- Diff: `just windows-chezmoi-diff`              # invokes scripts/windows-chezmoi-diff.sh via bash
- Apply: `just windows-chezmoi-apply`            # invokes scripts/windows-chezmoi-apply.sh via bash

Notes:
- The Just recipes call helper scripts in scripts/ so you don't need to set executable bits to use them.
- If you prefer to run the scripts directly, mark them executable:
  - `chmod +x scripts/windows-chezmoi-*.sh`
  - then run `scripts/windows-chezmoi-diff.sh` or `scripts/windows-chezmoi-apply.sh`

Manual Commands
- Discover Windows home: `powershell.exe -NoProfile -Command "$env:USERPROFILE" | tr -d '\r'`
- Convert to WSL path: `wslpath "C:\\Users\\You"`
- Preview: `CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff --source "$HOME/dotfiles" --destination "/mnt/c/Users/You" --verbose`
- Apply: `chezmoi apply --source "$HOME/dotfiles" --destination "/mnt/c/Users/You" --verbose`

Paths managed by this repo for Windows
- `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` → `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- (Also allowed if used) `AppData/**`

Troubleshooting
- If `powershell.exe` is not found, ensure you are running in WSL and that Windows PowerShell is available via interop.
- If the diff seems empty, verify the whitelist in `.chezmoiignore` includes `Documents/**` and your templates exist.
