# Windows How‑to

This page consolidates Windows usage and links to detailed guides.

Primary references

- Manage Windows profile from WSL: docs/how-to/chezmoi-windows.md
- WSL ↔ Windows PowerShell integration details: docs/how-to/WSL-Windows-pwsh-integration.md

Common tasks

- Set up Windows PowerShell 7 to load this repo (from WSL)
  ```bash
  just setup-pwsh7
  ```
  - When to use: WSL environment present; configure Windows pwsh to source this repo.
  - Why it matters: Windows shells share the same profile and functions defined here.

- Preview/apply Windows‑side chezmoi changes (from WSL)
  ```bash
  just windows-chezmoi-diff
  just windows-chezmoi-apply
  ```
  - When to use: manage Windows PowerShell profile and other `Documents/` files.
  - Why it matters: `.chezmoiignore` intentionally avoids direct writes to Windows profile from Linux/macOS flows.
  - If helpers fail: use manual commands in docs/how-to/chezmoi-windows.md.

- Verify Windows profile resolving this repo
  ```bash
  just verify-windows-profile
  just verify-windows-theme
  ```
  - When to use: after profile/theme changes.

- Switch Oh My Posh theme (Windows)
  ```bash
  just list-windows-themes
  just set-windows-theme powerlevel10k_modern
  ```

Notes and caveats

- PowerShell profile path: `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` is rendered from this repo but applied via helper flows to avoid conflicts; check `.chezmoiignore`.
- Some helper scripts under `scripts/` for Windows are evolving; prefer the manual chezmoi commands in docs/how-to/chezmoi-windows.md if a helper exits early.

