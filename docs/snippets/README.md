Windows Terminal Profile Snippets

How to use
- Open Windows Terminal → Settings (Ctrl+,) → Open JSON.
- Copy the object under `profiles.list[0]` from the JSON file you need and paste it into your settings’ `profiles.list` array.
- Ensure `defaultProfile` matches the profile’s `guid` if you want it as default.
- Adjust fields as needed:
  - `distribution`: your WSL distro name (e.g., `Ubuntu-24.04`)
  - `startingDirectory`: leave empty for default WSL home or keep the provided UNC path
  - `font.face`: any installed Nerd Font
  - `commandline`: add `--exec /usr/bin/zsh -l` if you want zsh without changing your default shell

Generate a new GUID (recommended)
- PowerShell: `New-Guid | % Guid`
- Replace both `guid` and `defaultProfile` with the new value.

Included files
- `windows-terminal-ubuntu-profile.json`: Portable WSL profile using your default WSL distro and MesloLGS Nerd Font.

Notes
- This portable profile launches your default WSL distro (`wsl.exe`). If you want to pin a specific distro, update:
  - `name`: e.g., `Ubuntu-24.04 (WSL)`
  - `commandline`: `wsl.exe -d Ubuntu-24.04`
  - Optionally add `startingDirectory`: `"//wsl.localhost/Ubuntu-24.04/home/%USERNAME%"` (or leave it out to start in the WSL home by default)
