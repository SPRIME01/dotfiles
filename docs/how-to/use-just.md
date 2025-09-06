# How to Use just (Task‑oriented)

There are two justfiles in this project:

- Global justfile installed by chezmoi: `dot_justfile` → targets `~/.justfile`
- Project justfile in this repo: `justfile` (many repo-specific tasks)

This page enumerates the global recipes from `dot_justfile` and how to use them. Use `just --list` and `just --choose` to discover and run tasks interactively.

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

Notes

- The project `justfile` in this repo exposes many additional tasks (e.g., Windows/WSL integration, SSH Agent Bridge). Discover them with `just --list` while inside the repo. For SSH Agent Bridge specifics, see docs/how-to/ssh-agent-bridge-cheatsheet.md.

