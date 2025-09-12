# How to Use chezmoi (Task‑oriented)

Core commands this repo relies on, plus when/why to use each. Always prefer diff → apply.

Environment tips

- Disable pagers for scriptable output: `CHEZMOI_NO_PAGER=1 PAGER=cat`
- Ignore semantics: `.chezmoiignore` patterns match destination paths (e.g., `.bashrc`, `.config/...`), not source names.
- Deny‑all whitelist example (dotfiles focus):
  ```
  *
  !.chezmoiignore
  !.*
  !.*/**
  ```
- Avoid this anti‑pattern: `!dot_*` (does not match any destination; will yield 0 managed entries).

Common tasks

- Initialize with local source (used by `install.sh`)
  ```bash
  chezmoi init --source="$HOME/dotfiles"
  ```
  - When to use: first time adopting this repo locally.
  - Why it matters: points chezmoi at this repo as the source of truth.
  - Note: `install.sh` validates `.chezmoiignore` and auto‑remediates any `!dot_*` patterns to a destination‑based whitelist.

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

Repo helpers (just)

- Quick status with validation
  ```bash
  just chezmoi-status
  ```
  - Shows version, resolved `sourceDir`, and managed count.
  - Warns if `.chezmoiignore` contains the invalid `!dot_*` pattern.

- Validate/fix ignore
  ```bash
  just chezmoi-validate-ignore   # detect bad patterns
  just chezmoi-fix-ignore        # write destination-based whitelist
  ```

- Sync source content into default source
  ```bash
  just chezmoi-sync-templates    # syncs templates/ → ~/.local/share/chezmoi/templates
  just chezmoi-sync-to-default   # syncs dot_* and calls chezmoi-sync-templates first
  ```

- Safe diff (with guard)
  ```bash
  just chezmoi-diff
  ```
  - Refuses to run if a bad `!dot_*` pattern is detected; suggests remediation.

Windows-specific (run from WSL)

- Preview/apply Windows‑side changes (see docs/how-to/chezmoi-windows.md)
  ```bash
  just windows-chezmoi-diff
  just windows-chezmoi-apply
  ```
  - When to use: Windows PowerShell profile and other `Documents/` content.
  - Why it matters: `.chezmoiignore` intentionally avoids direct writes to Windows profile; helpers manage it safely.
  - Note: These helpers validate and auto‑fix the source `.chezmoiignore` before invoking chezmoi on Windows.

Ordering guidance

1) diff → 2) apply → 3) verify (`scripts/doctor.sh`, `chezmoi doctor`). For Windows, insert the WSL helpers between 2 and 3 when needed.

Pitfalls

- Don’t hand‑edit generated files in `$HOME` that have templates; use `chezmoi edit` instead.
- If a diff looks empty on Windows from WSL, ensure `Documents/**` is whitelisted (it is by default) and see docs/how-to/chezmoi-windows.md for `--destination` usage.
- If `chezmoi managed` returns 0 unexpectedly, check for an invalid `!dot_*` pattern:
  ```bash
  just chezmoi-validate-ignore || just chezmoi-fix-ignore
  ```

Minimal troubleshooting

1) Validate ignore: `just chezmoi-validate-ignore`
2) Status: `just chezmoi-status`
3) Diff: `just chezmoi-diff` (guarded)
4) If needed, sync: `just chezmoi-sync-templates && just chezmoi-sync-to-default`
