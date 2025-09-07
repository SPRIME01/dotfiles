# How to Use chezmoi (Task‑oriented)

Core commands this repo relies on, plus when/why to use each. Always prefer diff → apply.

Environment tips

- Disable pagers for scriptable output: `CHEZMOI_NO_PAGER=1 PAGER=cat`
- Whitelist: `.chezmoiignore` defaults to deny‑all; only explicit paths/templates apply.

Common tasks

- Initialize with local source (used by `install.sh`)
  ```bash
  chezmoi init --source="$HOME/dotfiles"
  ```
  - When to use: first time adopting this repo locally.
  - Why it matters: points chezmoi at this repo as the source of truth.

- Preview changes (diff)
  ```bash
  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff --source "$HOME/dotfiles" --verbose
  ```
  - When to use: before changing files in `$HOME`.
  - Why it matters: safe, non-destructive planning step.

- Apply changes
  ```bash
  chezmoi apply --source "$HOME/dotfiles" --verbose
  ```
  - When to use: after reviewing the diff.
  - Why it matters: applies only explicitly included files.

- Check status
  ```bash
  chezmoi status
  ```
  - When to use: see local changes relative to templates.
  - Why it matters: guides whether to re‑add or adjust templates.

- List managed files
  ```bash
  chezmoi managed
  ```
  - When to use: discover what chezmoi owns.
  - Why it matters: avoid editing generated targets by hand when a template exists.

- Edit a file via chezmoi
  ```bash
  chezmoi edit ~/.zshrc
  ```
  - When to use: to change a managed target safely via its source template.
  - Why it matters: opens the underlying source (e.g., `dot_zshrc.tmpl`).

- Re‑add: capture a target file back into the source
  ```bash
  chezmoi re-add ~/.gitignore_global
  ```
  - When to use: promote a one‑off file in `$HOME` into the managed source.
  - Why it matters: preserves the change across machines via templates.

- Navigate to chezmoi source
  ```bash
  chezmoi cd
  ```
  - When to use: edit templates and scripts directly.
  - Why it matters: puts you in the correct working tree.

- Doctor
  ```bash
  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
  ```
  - When to use: after bootstrap, troubleshooting, CI checks.
  - Why it matters: diagnoses config, templates, and runtime.

Windows-specific (run from WSL)

- Preview/apply Windows‑side changes (see docs/how-to/chezmoi-windows.md)
  ```bash
  just windows-chezmoi-diff
  just windows-chezmoi-apply
  ```
  - When to use: Windows PowerShell profile and other `Documents/` content.
  - Why it matters: `.chezmoiignore` intentionally avoids direct writes to Windows profile; helpers manage it safely.

Ordering guidance

1) diff → 2) apply → 3) verify (`scripts/doctor.sh`, `chezmoi doctor`). For Windows, insert the WSL helpers between 2 and 3 when needed.

Pitfalls

- Don’t hand‑edit generated files in `$HOME` that have templates; use `chezmoi edit` instead.
- If a diff looks empty on Windows from WSL, ensure `Documents/**` is whitelisted (it is by default) and see docs/how-to/chezmoi-windows.md for `--destination` usage.

