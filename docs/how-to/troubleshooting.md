# Troubleshooting Hub

Central guide for resolving common issues encountered with the dotfiles setup.

## Table of Contents
- Shell Initialization Issues
- VS Code Settings Not Applying
- Oh My Posh / Prompt Problems
- SSH Agent Bridge Failures
- Projects Directory / Windows Link Issues
- PowerShell Profile Loading Issues
- Remote Development / SSH Server Problems

## Shell Initialization Issues
Symptoms: Aliases/functions missing, errors on new shell.
Checks:
1. Verify `.shell_common` symlink exists in home: `ls -l ~/.shell_common`
2. Run `just diagnose-shell`
3. Ensure `set -euo pipefail` not removed in modified scripts.

## VS Code Settings Not Applying
1. Run `bash install/vscode.sh` manually and inspect output — the script auto-detects your platform (wsl | linux | darwin | windows). You may pass a platform override as the first argument (optional).
2. Ensure `jq` is installed; the script attempts to install it when possible.
3. Check merged settings file location for your platform:
   - Linux: `~/.config/Code/User/settings.json`
   - macOS: `~/Library/Application Support/Code/User/settings.json`
   - Windows: `%APPDATA%/Code/User/settings.json`
   - WSL (Remote‑WSL server): `~/.vscode-server/data/Machine/settings.json` and Windows side (when using Remote‑WSL): `/mnt/c/Users/<USER>/AppData/Roaming/Code/User/settings.json`

## Oh My Posh / Prompt Problems
1. Confirm binary: `oh-my-posh version`
2. Reinstall pinned version: `bash scripts/install-oh-my-posh.sh`
3. Zsh only: run `p10k configure` to regenerate theme config.

## SSH Agent Bridge Failures
1. Ensure Windows tools (npiperelay) installed.
2. Confirm `SSH_AUTH_SOCK` points to relay socket inside WSL.
3. Restart shell; check log lines for bridge initialization.

## Projects Directory / Windows Link Issues
1. Run `bash scripts/setup-projects-idempotent.sh` again.
2. If symlink creation failed, use batch fallback `projects.bat`.
3. To force new symlink, remove `C:\Users\<user>\projects` (as admin) then rerun setup.

## PowerShell Profile Loading Issues
1. Launch `pwsh -NoProfile` then manually source profile path.
2. Check `$env:DOTFILES_ROOT` is set in profile.
3. Run `just setup-pwsh7` for reconfiguration.

## Remote Development / SSH Server Problems
1. Validate WSL2 context: `echo $WSL_DISTRO_NAME` non-empty.
2. Confirm `sshd` running: `pgrep -x sshd`.
3. Re-run `just setup-wsl2-remote`.
4. Ensure Windows firewall rule exists via Windows PowerShell script logs.

## General Tips
- Re-run unified wizard: `just setup`
- Lint scripts if modifications cause failures: `just lint`
- Check state file: `cat ~/.dotfiles-state` for component statuses.
