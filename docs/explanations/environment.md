<!--
  Environment configuration and secrets management guidance for the dotfiles project.
  This document explains how to use the provided `.env` file, how variables are
  loaded into your shell sessions across bash, zsh and PowerShell, and how to
  customise environment behaviour without editing core scripts.
-->

# 🧪 Environment Configuration & Secret Management

The **dotfiles** project now includes a unified mechanism for loading
configuration variables from **dotenv‑style files**.  This allows you to
define values such as API keys, project paths and custom flags in one place
and have them automatically imported into **Bash**, **Zsh** and
**PowerShell** sessions.  In this guide you’ll learn how to set up your own
`.env` file, how the loader works, and how to extend the configuration
to suit your needs.

## 📦 Getting Started

1. Copy the provided example to create your own environment file:

   ```bash
   cd ~/dotfiles               # navigate to the repository root
   cp .env.example .env        # create your personal config file
   $EDITOR .env                # edit values as needed
   ```

   The `.env` file is **ignored by Git** (see `.gitignore`) so it can
   safely contain secrets or machine‑specific values.

2. Define any variables you need.  Example:

   ```ini
   # Root directory for projects (overrides default of $HOME/Projects)
   PROJECTS_ROOT="$HOME/Work/Projects"

   # API secrets for MyCoolPlatform (MCP) integration
   MCP_GATEWAY_URL="https://api.mycoolplatform.com/v1"
   MCP_ADMIN_USERNAME="admin@example.com"
   MCP_ADMIN_PASSWORD="PLACEHOLDER"  # replace with real value in your local .env

   # Node package manager config
   PNPM_HOME="$HOME/.pnpm-global"
   ```

3. (Optional) Create additional environment files and load them by
   setting `DOTFILES_ADDITIONAL_ENV` before launching your shell.  This
   allows you to split secrets into multiple files, e.g. per project or
   per environment.

   ```bash
   export DOTFILES_ADDITIONAL_ENV="$HOME/.extra_secrets"
   ```

   When you open a new shell the loader will import both `.env` and the
   file specified by `DOTFILES_ADDITIONAL_ENV`.

## 🔍 How It Works

### Linux (Bash/Zsh)

* The shared configuration file [`.shell_common.sh`](../.shell_common.sh)
  determines the location of the dotfiles repository at runtime.  It then
  sources [`scripts/load_env.sh`](../scripts/load_env.sh), which defines a
  `load_env_file` function.  This function parses dotenv files without
  executing code and exports each key/value pair into your shell.

* Upon startup, `.shell_common.sh` calls:

  ```bash
  load_env_file "$DOTFILES_ROOT/.env"
  load_env_file "$DOTFILES_ROOT/mcp/.env"
  ```

  This means values from `.env` override defaults like `PROJECTS_ROOT`
  defined in `.shell_common.sh`, and values from `mcp/.env` are also
  imported.  If you have set `DOTFILES_ADDITIONAL_ENV`, that file will
  be loaded in your Zsh profile (`zsh/env.zsh`).

### Windows PowerShell

* A complementary loader script lives at
  [`PowerShell/Utils/Load-Env.ps1`](../PowerShell/Utils/Load-Env.ps1).  It
  defines the `Load-EnvFile` function that accepts a file path and populates
  `$env:` variables.  You can also run this script directly to load a file
  into your current PowerShell session:

  ```powershell
  # Example: manually import variables
  . "$env:DOTFILES_ROOT\PowerShell\Utils\Load-Env.ps1"
  Load-EnvFile -FilePath "$HOME\dotfiles\.env"
  ```

* During PowerShell startup, the profile
  [`Microsoft.PowerShell_profile.ps1`](../PowerShell/Microsoft.PowerShell_profile.ps1)
  sets `$env:DOTFILES_ROOT` and `$env:PROJECTS_ROOT` based on the profile
  location, then loads both `.env` and `mcp/.env` via the loader.  This
  ensures that all your PowerShell functions (e.g. in `Get-SecretKey.ps1`) can
  access the same environment variables as your bash/zsh shells.

## 🧰 Additional Tools

### direnv Integration (Bash, Zsh & PowerShell)

The project includes **optional** support for [direnv](https://direnv.net), which
automatically loads and unloads per-directory environment variables defined in
`.envrc` files. If `direnv` is installed it is enabled automatically for:

* `bash` / `zsh` via the modular loader (`shell/common/direnv.sh`)
* `pwsh` (PowerShell 7) via logic in `shell/powershell/config.ps1`

If it is not installed, the hooks quietly do nothing. You do **not** need to
add manual `eval "$(direnv hook <shell>)"` lines to your personal rc/profile
files—duplication could slow down shell startup.

Install and enable (Linux / macOS examples):

```bash
sudo apt install -y direnv        # Debian/Ubuntu
# or: brew install direnv          # Homebrew (macOS/Linux)
# or: sudo dnf install -y direnv   # Fedora
# or: sudo pacman -Sy --noconfirm direnv  # Arch
# or: sudo zypper install -y direnv       # openSUSE

# (Optional) prevent verbose logging
export DIRENV_LOG_FORMAT=""

Windows (in a Windows PowerShell or pwsh session):

```powershell
scoop install direnv   # Scoop
# or
choco install direnv -y
```
```

To temporarily disable direnv without uninstalling it:

```bash
export DISABLE_DIRENV=1
```

To re‑enable, unset the variable:

```bash
unset DISABLE_DIRENV
```

Add project specific settings by creating a `.envrc` in the directory and then
authorising it once:

```bash
echo 'export FOO=bar' > .envrc
direnv allow
```

PowerShell notes:

* Hook auto‑loads only once per session (guard: `DOTFILES_DIRENV_PWSH_INITIALIZED`).
* You can still run `direnv status` or `direnv reload` manually.

Helper functions (bash/zsh) added by the loader:

* `direnv_quiet` – silence direnv logging (sets `DIRENV_LOG_FORMAT` empty)
* `direnv_verbose` – restore default logging (unsets `DIRENV_LOG_FORMAT`)
* `direnv_status` – shortcut wrapper around `direnv status`

Examples:

```bash
direnv_verbose   # show load/unload events
direnv_quiet     # suppress messages again
direnv_status    # inspect current state
```

Because the hook logic is centralized, you should **not** add extra
`direnv hook` invocations to your personal rc/profile files; duplication can
cause redundant evaluations and slower startup.

### Post‑Commit Hook for Aliases

The directory `scripts/git-hooks` now contains a sample **post‑commit** hook
that automatically regenerates the PowerShell aliases module after each
commit.  To enable it:

```bash
cp scripts/git-hooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

Whenever you commit a new function under `PowerShell/Modules/Aliases`, the hook
will run `Invoke-UpdateAliasesModule` via PowerShell to rebuild
`Aliases.psm1`.  If PowerShell (`pwsh`) is not available, it prints a warning
but does not block your commit.

### Enhanced Update Logic

The update scripts (`update.sh` and `update.ps1`) now stash any uncommitted
changes before running `git pull` and reapply them afterwards.  This
prevents accidental merge conflicts if you have local modifications.  If
you would like to disable this behaviour, you can comment out the stashing
logic in the scripts.

### SSH Agent Bridge

For WSL2 users who wish to use their **Windows OpenSSH agent** in WSL
without duplicating keys, a consolidated script lives at
[`scripts/setup-ssh-agent-bridge.sh`](../scripts/setup-ssh-agent-bridge.sh).
This script checks if you are running in WSL2, starts
`wsl-ssh-agent-relay` and `socat` as needed, and exports `SSH_AUTH_SOCK` to
point at a Unix socket inside your WSL home directory.  It is sourced by
both `.bashrc` and `.zshrc` automatically, so there is no need to copy
lengthy bridging code into your profiles. See the tutorial in
[WSL2 + Windows SSH Agent](../tutorials/ssh.md) for
detailed instructions.

---

By centralising configuration in `.env` files and providing robust
loaders for each shell, your environment stays DRY and secure.  You can
freely customise variables without modifying core scripts, and the loader
ensures that changes propagate consistently across all shells.  If you need
to manage secrets (API keys, tokens) for multiple services, consider using
separate `.env` files and setting `DOTFILES_ADDITIONAL_ENV` to point to
them.  Happy hacking!
