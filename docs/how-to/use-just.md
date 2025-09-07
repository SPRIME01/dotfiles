# How to Use just (Task‑oriented)

There are two justfiles in this project:

- Global justfile installed by chezmoi: `dot_justfile` → targets `~/.justfile`
- Project justfile in this repo: `justfile` (many repo-specific tasks)

This page enumerates the global recipes from `dot_justfile` and highlights key project recipes from the repo `justfile`. Use `just --list` and `just --choose` to discover and run tasks interactively.

Discovery

```bash
just --list      # show available recipes
just --choose    # interactive chooser (if supported by your just version)
```

Global recipes (dot_justfile)

- default
  - Purpose: print the available global tasks.
  - When to run: anytime you need a quick refresher.
  - Example:
    ```bash
    just
    ```

- bootstrap
  - Purpose: apply chezmoi, then run `mise install` if available.
  - Dependencies: chezmoi; optional mise.
  - When to run: first setup; after pulling template changes.
  - Example:
    ```bash
    just bootstrap
    ```

- lint
  - Purpose: placeholder message; add project-specific linters per repo.
  - When to run: n/a (informational).
  - Example:
    ```bash
    just lint
    ```

- format
  - Purpose: placeholder message; add project-specific formatters per repo.
  - When to run: n/a (informational).
  - Example:
    ```bash
    just format
    ```

- direnv-install
  - Purpose: idempotent, cross‑platform direnv installation.
  - Dependencies: a supported package manager (apt, dnf, pacman, zypper, brew, scoop, choco).
  - When to run: once per machine; re-run after OS reinstall.
  - Example:
    ```bash
    just direnv-install
    direnv version
    ```

- windows-chezmoi-diff
  - Purpose: from WSL, preview Windows‑side changes using helper script.
  - Dependencies: WSL interop (`powershell.exe`), chezmoi.
  - When to run: before applying Windows‑side changes.
  - Example:
    ```bash
    just windows-chezmoi-diff
    ```

- windows-chezmoi-apply
  - Purpose: from WSL, apply Windows‑side changes using helper script.
  - Dependencies: WSL interop (`powershell.exe`), chezmoi.
  - When to run: after inspecting the diff.
  - Example:
    ```bash
    just windows-chezmoi-apply
    ```

Project recipes (repo justfile)

- setup-pwsh7
  - Purpose: from WSL, configure Windows PowerShell 7 to load this repo’s profile.
  - Example:
    ```bash
    just setup-pwsh7
    ```

- verify-windows-profile
  - Purpose: verify that Windows $PROFILE points at this repo and initializes correctly.
  - Example:
    ```bash
    just verify-windows-profile
    ```

- verify-windows-theme
  - Purpose: verify Oh My Posh is available on Windows and the configured theme resolves.
  - Example:
    ```bash
    just verify-windows-theme
    ```

- list-windows-themes
  - Purpose: list available Oh My Posh themes in `PowerShell/Themes`.
  - Example:
    ```bash
    just list-windows-themes
    ```

- set-windows-theme
  - Purpose: set the `OMP_THEME` for Windows and reinitialize the current prompt if possible.
  - Example:
    ```bash
    just set-windows-theme powerlevel10k_modern
    ```

- windows-chezmoi-diff-apply
  - Purpose: convenience alias to run `windows-chezmoi-diff` then `windows-chezmoi-apply`.
  - Example:
    ```bash
    just windows-chezmoi-diff-apply
    ```

- verify-windows-mise-dotenv
  - Purpose: verify Mise activation and dotenv loading in Windows PowerShell (run from WSL).
  - Example:
    ```bash
    just verify-windows-mise-dotenv
    ```

Notes

- The project `justfile` in this repo exposes many additional tasks (e.g., Windows/WSL integration, SSH Agent Bridge). Discover them with `just --list` while inside the repo. For SSH Agent Bridge specifics, see docs/how-to/ssh-agent-bridge-cheatsheet.md.
