# Troubleshooting

Quick checks

- scripts/doctor.sh
  ```bash
  bash scripts/doctor.sh               # add --verbose or --strict
  ```
- chezmoi doctor
  ```bash
  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
  ```
- direnv
  ```bash
  direnv status
  ```

Common symptoms and fixes

- Permission issues on `$HOME`
  - Symptom: doctor reports unwritable home or projects dir.
  - Fix: ensure user write perms; create `~/projects` if missing.

- direnv not loading
  - Symptom: no environment changes when cd into repo.
  - Fix: confirm hook (open a new shell), then `direnv allow` and `direnv status`.

- chezmoi diff shows nothing but files didn’t update
  - Symptom: expected changes not appearing.
  - Fix: check `.chezmoiignore` whitelist; verify `--source` path and, on Windows, use helpers or manual `--destination`.

- Windows path quirks
  - Symptom: UNC path not ready on pwsh startup, theme missing.
  - Fix: re-run `just setup-pwsh7`; open a new Windows PowerShell session; use `just verify-windows-profile`.

More

- See docs/how-to/troubleshooting.md for deeper, topic-specific guides (VS Code, SSH Agent Bridge, etc.).

