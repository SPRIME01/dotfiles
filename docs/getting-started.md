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
bash install.sh
```

- When: First install on a new machine.
- Why: Installs/initializes chezmoi against this repo and applies safe templates.

2) Validate environment

```bash
bash scripts/doctor.sh
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

