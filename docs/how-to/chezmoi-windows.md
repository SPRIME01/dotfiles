# Manage Windows Profile from WSL

Use these commands to preview and apply Windows-side changes (for example, your PowerShell profile) from WSL.
Prerequisites
- WSL access to Windows (`powershell.exe` available from WSL)
- chezmoi installed in WSL
- This repo is your chezmoi source (default `~/dotfiles`)

Quick Recipes (recommended)
- Diff: `just windows-chezmoi-diff`
- Apply: `just windows-chezmoi-apply`

Notes:
- Override the source repo path if not `~/dotfiles`:
  - `just windows-chezmoi-diff SRC=/path/to/repo`
  - `just windows-chezmoi-apply SRC=/path/to/repo`

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
