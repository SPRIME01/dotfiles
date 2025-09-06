# Update an Existing Machine (Tutorial)

Goal: safely update your dotfiles while seeing what will change, then verify and recover if needed.

1) Pre-flight checks
   ```bash
   # Optional local edits? Confirm before pulling or applying
   git -C "$HOME/dotfiles" status --porcelain || true

   # Basic environment health
   bash "$HOME/dotfiles/scripts/doctor.sh"
   CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
   ```
   - When to use: always begin here.
   - Why it matters: avoid surprises from local changes or broken environment.

2) Review what chezmoi would change
   ```bash
   cd "$HOME/dotfiles"
   CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff --source "$PWD" --verbose
   ```
   - When to use: before applying updates.
   - Why it matters: diff-first avoids destructive surprises.

3) Apply changes
   ```bash
   # Apply to your home directory from this repo
   chezmoi apply --source "$PWD" --verbose
   ```
   - When to use: after inspecting the diff.
   - Why it matters: applies only whitelisted files (see .chezmoiignore).

4) Windows-specific updates (from WSL)
   ```bash
   # Preview Windows-side changes
   just windows-chezmoi-diff
   # Apply Windows-side changes
   just windows-chezmoi-apply
   ```
   - When to use: managing Windows PowerShell profile, etc., from WSL.
   - Why it matters: Windows profile is managed via helpers rather than direct chezmoi to Documents/.
   - If a helper fails: use manual commands in docs/how-to/chezmoi-windows.md.

5) Verify post-update
   ```bash
   bash scripts/doctor.sh
   CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
   direnv status
   ```
   - When to use: after apply.
   - Why it matters: confirms environment is consistent.

6) Optional: pull upstream changes to the repo itself
   - When to use: if you track this repo directly (rather than using chezmoi init with a remote).
   - Why it matters: updates project scripts and templates themselves.
   - Note: some references mention update.sh; if absent, use the commands above.

Flowchart: Safe update flow

```mermaid
flowchart TD
  A[Start] --> B[Check local edits (git status)]
  B --> C[Doctor + chezmoi doctor]
  C --> D[chezmoi diff]
  D --> E{OK to apply?}
  E -->|No| X[Stop & adjust]
  E -->|Yes| F[chezmoi apply]
  F --> G{Windows via WSL?}
  G -->|No| H[Verify]
  G -->|Yes| I[just windows-chezmoi-diff/apply]
  I --> H[Verify]
  H --> Z[Done]
```

Rollback considerations

- chezmoi templates are versioned in this repo. If an applied change misbehaves:
  - Inspect commit history: `git -C "$HOME/dotfiles" log -- templates/` or specific files.
  - Revert locally and re-apply: `git -C "$HOME/dotfiles" revert <commit>` then `chezmoi apply`.
  - For non-template files changed in $HOME, re-run `chezmoi apply` after fixing templates.

Verification checklist

- diff was reviewed before apply.
- doctor and chezmoi doctor pass.
- direnv status is healthy.
- Windows (if applicable): new PowerShell session loads profile, prompt renders correctly.

