# Commands Reference

Chezmoi

- Disable pager for scripts
  ```bash
  CHEZMOI_NO_PAGER=1 PAGER=cat
  ```
- Init with local source
  ```bash
  chezmoi init --source "$HOME/dotfiles"
  ```
- Diff → Apply → Verify
  ```bash
  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi diff --source "$HOME/dotfiles" --verbose
  chezmoi apply --source "$HOME/dotfiles" --verbose
  CHEZMOI_NO_PAGER=1 PAGER=cat chezmoi doctor
  ```
- Other
  ```bash
  chezmoi status
  chezmoi managed
  chezmoi edit ~/.zshrc
  chezmoi cd
  ```

Just (global `dot_justfile`)

```bash
just                  # print available global tasks
just bootstrap        # chezmoi apply + optional mise install
just direnv-install   # install direnv via PM (idempotent)
just windows-chezmoi-diff   # from WSL
just windows-chezmoi-apply  # from WSL
```

Just (repo `justfile`, selected)

- Discover inside the repo: `just --list`
- Windows/WSL integration examples:
  ```bash
  just setup-pwsh7
  just verify-windows-profile
  just verify-windows-theme
  just list-windows-themes
  just set-windows-theme powerlevel10k_modern
  ```
- SSH Agent Bridge: see docs/how-to/ssh-agent-bridge-cheatsheet.md for full list.

Direnv

```bash
direnv version
direnv allow
direnv status
# quiet / verbose helpers (bash/zsh)
direnv_quiet
direnv_verbose
```

Scripts (selected)

```bash
bash scripts/doctor.sh              # env diagnostic; add --verbose or --strict
bash scripts/install-direnv.sh      # installer wrapper (idempotent)
# WSL helpers (experimental). See docs/how-to/chezmoi-windows.md for manual fallbacks:
just windows-chezmoi-diff
just windows-chezmoi-apply
```

Common pitfalls

- Pager interference: set `CHEZMOI_NO_PAGER=1` and `PAGER=cat` for predictable output.
- Windows profile: managed via helper scripts rather than direct chezmoi apply (see `.chezmoiignore`).
- Don’t edit generated files in `$HOME` that have templates; use `chezmoi edit`.

