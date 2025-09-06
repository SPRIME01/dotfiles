# Repository Structure (Reference)

Key directories and files and what they do.

Top‑level

- `install.sh`: installs chezmoi if missing, initializes with this repo, then applies templates.
- `bootstrap.sh`: links shell configs and performs first‑run setup; idempotent.
- `justfile`: project tasks (inside repo); discover with `just --list`.
- `dot_justfile`: template for global `~/.justfile` installed by chezmoi (see docs/how-to/use-just.md).
- `.chezmoiignore`: deny‑by‑default; only explicit `dot_*`, `Documents/**`, `AppData/**` are applied; excludes Windows PowerShell profile target for safety.
- `.envrc` and `.envrc.example`: direnv configuration and patterns.

Templates

- `dot_zshrc.tmpl`: zsh configuration with direnv hook and OS‑specific PATH sections via partials.
- `templates/partials/*.tmpl`: reusable fragments (PATHs, direnv hook, ssh agent bridge, projects path, etc.).

Shell configuration (modular)

- `shell/loader.sh`, `shell/loader.ps1`: modular loader entrypoints.
- `shell/common/*`: shared env, aliases, and functions, including direnv hook for bash.
- `shell/platform-specific/*`: Linux/macOS/Windows‑specific settings.
- `shell/powershell/config.ps1`: PowerShell‑specific settings loaded by the profile integration.
- `.shell_common.sh`, `.shell_functions.sh`: legacy/common helpers sourced by bootstrap and loaders.

PowerShell

- `PowerShell/Microsoft.PowerShell_profile.ps1`: main profile; determines `DOTFILES_ROOT`, initializes Oh My Posh, loads modular integration.
- `PowerShell/Modules/*`: custom module (Aliases) and Terminal‑Icons.
- `scripts/setup-windows-pwsh7-profile.ps1` and related: set up Windows PowerShell profile to load this repo from WSL.

Scripts (selected)

- `scripts/doctor.sh`: environment diagnostic; supports `--verbose`, `--strict`.
- `scripts/install-direnv.sh`: cross‑platform direnv installer.
- `scripts/windows-chezmoi-diff.sh`, `scripts/windows-chezmoi-apply.sh`: WSL helpers to diff/apply Windows‑side changes (experimental).
- `scripts/setup-wizard.sh`: unified interactive setup combining shell, VS Code, projects, and Windows integration.
- `install/vscode.sh`: apply VS Code settings for your platform.

Windows integration

- See docs/how-to/chezmoi-windows.md and docs/how-to/WSL-Windows-pwsh-integration.md for flows.

Tests

- `test/`: shell and PowerShell tests verifying idempotence, templates (direnv hooks present), global justfile management, etc. Use them as behavioral references (do not run destructive tasks in production shells).

