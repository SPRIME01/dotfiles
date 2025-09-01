# Windows PowerShell 7 Integration (via WSL)

This repo can configure your Windows PowerShell 7 profile from WSL. It prefers a symlink to the repo profile; if that’s not possible, it writes a small loader that imports the profile from WSL using a UNC path.

## Quick Start

- From WSL: `just setup-pwsh7`
- Verify: `just verify-windows-profile`
- Set theme: `just set-windows-theme powerlevel10k_modern`

## How It Works

- The recipe runs in WSL but targets the Windows host, invoking `powershell.exe`/`pwsh.exe`.
- It computes your Windows profile path (handles OneDrive paths) and prefers to create a symlink to `PowerShell/Microsoft.PowerShell_profile.ps1` in this repo.
- If symlink creation isn’t possible (Developer Mode off or policy), it writes a loader profile that:
  - Sets `DOTFILES_ROOT` to `\\wsl.localhost\<distro>\home\<user>\dotfiles` (with a fallback to `\\wsl$\<distro>`),
  - Imports the repo profile if reachable,
  - Falls back to a minimal setup if not reachable.

## Commands

- `just setup-pwsh7`: Creates the Windows profile (symlink or loader) and tests loading it with pwsh.
- `just setup-pwsh7-dry-run`: Shows intended actions without making changes.
- `just setup-pwsh7-symlink`: Forces symlink creation (fails if not possible).
- `just setup-pwsh7-symlink-admin`: Attempts an elevated symlink via Windows PowerShell (UAC prompt).
- `just verify-windows-profile`: Prints WindowsPowerShell (v5) and PowerShell 7 profile info.
- `just list-windows-themes`: Lists themes from `PowerShell/Themes` in this repo.
- `just set-windows-theme <theme>`: Sets `OMP_THEME` for your user and reinitializes the current pwsh session.

## Notes & Troubleshooting

- Developer Mode: Enable Windows Developer Mode to allow symlink creation without elevation (Settings → For Developers → Developer Mode).
- UNC Access: If `\\wsl.localhost\<distro>\...` isn’t reachable, the loader tries legacy `\\wsl$\<distro>\...` as a fallback.
- OneDrive Paths: The setup detects OneDrive-backed `Documents` paths and uses them automatically.
- Profiles:
  - WindowsPowerShell (v5) uses a different `$PROFILE` than PowerShell 7 (pwsh). This repo targets pwsh.
  - `verify-windows-profile` uses `-NoProfile` to inspect paths without loading profiles.
- Themes: `set-windows-theme` writes `OMP_THEME` to your user environment and tries to reinitialize `oh-my-posh` in the current pwsh. Ensure `oh-my-posh` is installed on Windows.

## Uninstall / Revert

- Remove loader/symlink: Delete `C:\Users\<you>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`.
- Clear theme: Remove `OMP_THEME` from Environment Variables (User) and restart pwsh.

