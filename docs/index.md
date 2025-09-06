# Dotfiles System — Overview and Quickstart

Welcome. This repository manages your shell and editor configuration across Linux, macOS, and Windows (including WSL) using three core tools:

- chezmoi: declarative dotfile management and templating
- direnv: per-directory environments with safe “allow” gates
- just: convenient task runner for repeatable tasks

Use the tutorials for the happy path and the how‑tos for common tasks. Reference pages list commands and structure; the explanation page shows how the pieces fit.

Quickstart

- Linux/macOS (recommended happy path)
  1) Clone and apply with chezmoi installer baked in:
     ```bash
     git clone https://github.com/SPRIME01/dotfiles "$HOME/dotfiles"
     cd "$HOME/dotfiles"
     bash install.sh
     ```
     - When to use: first setup on a Unix-like system.
     - Why it matters: installs chezmoi if missing; applies templates safely.

  2) Validate core health and environment:
     ```bash
     bash scripts/doctor.sh
     CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
     ```
     - When to use: after bootstrap, any time things feel off.
     - Why it matters: confirms basics (paths, git ignores, optional tools).

  3) Install direnv and enable in this repo:
     ```bash
     # Option A: from inside the repo using the project justfile
     just install-direnv
     # Option B: directly via the helper script
     bash scripts/install-direnv.sh

     direnv version
     direnv allow   # in the repo root (re-run after editing .envrc)
     direnv status
     ```
     - When to use: once per machine; re-run if direnv missing.
     - Why it matters: quiet, per-repo envs and PATH for tools in this repo.

- Windows
  - WSL integration (recommended): from WSL, after cloning/applying as above:
    ```bash
    # Sets up Windows PowerShell 7 to load this repo’s profile
    just setup-pwsh7

    # Preview/apply Windows-side changes managed by chezmoi from WSL
    just windows-chezmoi-diff
    just windows-chezmoi-apply
    ```
    Notes:
    - See docs/how-to/chezmoi-windows.md for manual commands and details.
    - The Windows chezmoi helper scripts are evolving; fall back to manual diff/apply if needed.

  - Native PowerShell (alternative):
    ```powershell
    # Bootstrap PowerShell with the repo’s profile and modules
    Invoke-RestMethod https://raw.githubusercontent.com/SPRIME01/dotfiles/main/bootstrap.ps1 | Invoke-Expression
    ```
    - When to use: on Windows without WSL, to load the PowerShell profile directly.

Table of contents

- Tutorials
  - docs/tutorials/new-machine-setup.md
  - docs/tutorials/update-existing-machine.md

- How‑to guides
  - docs/how-to/use-chezmoi.md
  - docs/how-to/use-just.md
  - docs/how-to/use-direnv.md
  - docs/how-to/windows.md
  - docs/how-to/chezmoi-windows.md (existing)
  - docs/how-to/WSL-Windows-pwsh-integration.md (existing)
  - docs/how-to/backup-and-restore.md (optional)

- Reference
  - docs/reference/repo-structure.md
  - docs/reference/commands.md
  - docs/reference/README.md (existing index)

- Explanation
  - docs/explanation/architecture.md

- Support
  - docs/troubleshooting.md
  - docs/how-to/troubleshooting.md (existing)
  - docs/glossary.md

Assumptions and notes

- Safe defaults first: diff before apply; verify after major steps.
- Windows PowerShell profile is intentionally managed with helper scripts rather than direct chezmoi apply to Documents/ (see .chezmoiignore). Use docs/how-to/chezmoi-windows.md for that flow.
- Some Windows scripts under scripts/ are experimental; if they fail, use the manual chezmoi diff/apply commands documented in docs/how-to/chezmoi-windows.md.

