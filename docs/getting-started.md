# Getting Started

Goal: Set up a new machine with this dotfiles repo using existing recipes in a safe, ordered flow.

## Prerequisites

- Git and `curl` or `wget` installed.
- Choose a projects directory (default: `~/projects`).

## Linux/macOS

1) Clone and bootstrap

```bash
git clone https://github.com/SPRIME01/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"
just install # or bash install.sh
```

- When: First install on a new machine.
- Why: Installs/initializes chezmoi against this repo and applies safe templates.

2) Validate environment

```bash
just doctor-verbose # or bash scripts/doctor.sh
CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
```

- When: Immediately after bootstrap.
- Why: Catches path/permission/config issues early.

3) Install direnv

```bash
# choose one
just install-direnv
# or
bash scripts/install-direnv.sh
direnv version
```

- When: Once per machine.
- Why: Enables per-directory environment management used across repos.

4) Enable direnv for this repo

```bash
# run in the repo root (where .envrc lives)
direnv allow
direnv status
```

- When: First time; repeat after editing `.envrc`.
- Why: Trusts the repo’s `.envrc` and activates environment on cd.

5) Verify Mise (optional but recommended)

```bash
mise --version
mise doctor || true
```

- When: After bootstrap if you plan to use Mise.
- Why: Confirms the default tool/version manager is working.

References: `tutorials/new-machine-setup.md`, `how-to/use-chezmoi.md`, `how-to/use-direnv.md`, `reference/commands.md`.

## Windows via WSL (recommended)

1) Do Linux steps inside WSL

- Command: same as Linux/macOS above from your WSL shell.
- Why: Keeps one source of truth and manages Windows from WSL.

2) Set up Windows PowerShell 7 profile from WSL

```bash
just setup-pwsh7
```

- When: After Linux steps inside WSL.
- Why: Makes Windows PowerShell load this repo’s profile via UNC.

What you get after setup
- `code .` from a UNC WSL path (for example, `\\wsl.localhost\\Ubuntu-24.04\\home\\<you>\\project`) opens VS Code via Remote‑WSL.
- `wslcode` helper always opens Remote‑WSL and converts Windows/UNC paths to Linux paths.

Examples
```powershell
# From Windows PowerShell 7
cd \\wsl.localhost\Ubuntu-24.04\home\<you>\Projects\myapp
code .           # Opens Remote‑WSL (auto)

# Anywhere (UNC or C:\), force Remote‑WSL
wslcode .
wslcode C:\Users\<you>\project
wslcode \\wsl.localhost\Ubuntu-24.04\home\<you>\project
```

3) Preview and apply Windows-side changes (from WSL)

```bash
just windows-chezmoi-diff
just windows-chezmoi-apply
```

- When: When applying Windows-side profile/config updates.
- Why: Windows profile is managed via helpers rather than direct writes.

4) Verify SSH agent bridge (optional quick check)

```bash
ssh-add -l || ssh-add
ssh -T git@github.com || true
```

- Why: Confirms keys are available to both environments; see cheatsheet for details.

References: `how-to/chezmoi-windows.md`, `tutorials/WSL2-Windows-setup.md`, `how-to/ssh-agent-bridge-cheatsheet.md`.

## Windows Native PowerShell (no WSL)

1) Bootstrap PowerShell

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/SPRIME01/dotfiles/main/bootstrap.ps1 | Invoke-Expression
```

- When: First setup without WSL.
- Why: Configures your PowerShell to load from this repo.

2) Validate

```powershell
oh-my-posh --version
$env:DOTFILES_ROOT
```

- When: After bootstrap.
- Why: Confirms prompt tooling and repo wiring are active.

References: `windows-powershell-setup.md`, `how-to/windows.md`.

## Safe Ordering Tips

- Diff before apply when unsure:

```bash
CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff
```

- Most scripts are idempotent: re-run safely if a step fails; review `.chezmoiignore` for whitelisted targets.

## Verification Checklist

- `bash scripts/doctor.sh` shows no blockers.
- `CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor` is healthy.
- `direnv status` shows this repo is allowed and active.
- Shell (zsh/bash) loads repo paths/aliases; on WSL, new Windows PowerShell sessions use the repo profile and prompt.

## Helpful Recipes Summary

- Core
  - `bash install.sh` (bootstrap)
  - `bash scripts/doctor.sh` and `chezmoi doctor` (validate)
  - `just install-direnv` or `bash scripts/install-direnv.sh` (direnv install)
  - `direnv allow` (enable per-dir env)

- Windows via WSL
  - `just setup-pwsh7` (configure Windows pwsh)
  - `just windows-chezmoi-diff` and `just windows-chezmoi-apply` (Windows-side apply)

- Global just (installed by chezmoi; optional)
  - `just bootstrap` (chezmoi apply + optional Mise install)
  - `just direnv-install` (cross-platform direnv installation)

## Mise Activation Notes

- Scoped activation (recommended): This repo activates mise via direnv only inside allowed projects. Outside a project, `mise doctor` may show `activated: no` and `shims_on_path: no` — that’s expected.
- Verify in-project: After `direnv allow` in this repo (or any project with `.envrc` + `.mise.toml`), `mise doctor` should report `activated: yes`. Example checks:

```bash
mise doctor || true
mise which node  # or any tool defined in your .mise.toml
```

- Optional shims (global/non-interactive): If you need tools available without direnv, add `~/.local/share/mise/shims` to `PATH` or use `eval "$(mise activate zsh --shims)"` (adjust for your shell). This is not required for the direnv-first flow.
- Updates: If `mise doctor` reports a newer version is available, update with `mise self-update`.

### Why this repo does not add `eval "$(mise activate <shell>)"` globally

This setup is intentionally “scoped activation”: tools only appear when you are inside an allowed project (direnv + [.envrc](http://_vscodecontentref_/0) + optional `.mise.toml`). Benefits:
- Faster generic shell startup (no global hook-env runs).
- Avoids PATH bloat and accidental tool version leakage into unrelated scripts.
- Clear boundary: enter project → tools available; leave project → PATH clean.

You will see `mise doctor` show `activated: no` outside allowed dirs—this is expected.

### Temporary or global opt‑in (optional)

One-off (current shell only):
```bash
eval "$(mise activate bash)"   # or zsh
```

Prefer shims only (lighter, fewer features):
```bash
eval "$(mise activate bash --shims)"
```

Permanent (add to your own *personal* rc, not managed by chezmoi):
```bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
# or for zsh
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
```

## SSH

GitHub Copilot

Recommended sequence (WSL2 + Windows, fresh machine, wanting SSH agent bridge):

1. Preflight (sanity + dependency checks)
```bash
just ssh-bridge-preflight
```

2. Install Windows side (run from WSL; sets up Windows agent + manifest)
```bash
just ssh-bridge-install-windows
# Dry run: just ssh-bridge-install-windows-dry-run
```

3. Install WSL side bridge (creates launcher, rc blocks, socket)
```bash
just ssh-bridge-install-wsl
# Dry run: just ssh-bridge-install-wsl-dry-run (if present) or use --dry-run flag if script supports
```

4. (Optional) Fix/repair config if something didn’t wire correctly
```bash
just ssh-bridge-fix-config
# Or dry-run: just ssh-bridge-fix-config-dry-run
```

5. (Optional) Deploy your public key to LAN/remote hosts
```bash
just ssh-bridge-deploy           # full deploy using hosts file
# Variants:
just ssh-bridge-deploy-dry-run
just ssh-bridge-deploy-custom only="host1,host2" exclude="oldhost"
```

6. (Optional, first-time host trust + hardening flow)
```bash
just ssh-bridge-lan-bootstrap
# Dry run: just ssh-bridge-lan-bootstrap-dry-run
```

7. (Optional) Rotate Windows key then redeploy
```bash
just ssh-bridge-rotate-deploy
# Dry run: just ssh-bridge-rotate-deploy-dry-run
```

8. (Maintenance) List or clean up
```bash
just ssh-bridge-list-hosts
just ssh-bridge-cleanup-old-keys DIR=./old_keys_backup   # after verification
```

Minimal happy path (most users):
```
just ssh-bridge-preflight
just ssh-bridge-install-windows
just ssh-bridge-install-wsl
ssh-add -l
```

Linux-only (no Windows): you don’t need the bridge—just generate keys and use ssh-agent (skip all ssh-bridge-* recipes).

Windows-only (no WSL): run the PowerShell bootstrap; bridge recipes are WSL-focused.

Need a condensed one-liner? Use:
```
just ssh-bridge-preflight && just ssh-bridge-install-windows && just ssh-bridge-install-wsl
```
