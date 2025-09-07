# Backup and Restore (Optional)

This repo keeps source of truth under version control; the rendered files in `$HOME` are reproducible via chezmoi. Back up the repo (and any private dotenv files) to preserve your setup.

What to back up

- The repository itself (including templates and scripts)
- Private dotenv files if used:
  - `.env` (ignored by git)
  - `mcp/.env` (ignored)
- SSH keys and tokens are NOT part of this repo by design; manage them separately.

Restore on a new machine

```bash
# Fresh clone and apply
git clone https://github.com/SPRIME01/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"
bash install.sh
# Restore private dotenvs if you kept backups
# e.g., cp ~/Backups/dotfiles/.env ./.env
# Re-enable direnv
direnv allow
```

Safety notes

- Avoid copying generated files from `$HOME` back into this repo; use `chezmoi re-add` instead when you intend to manage a target.
- Keep secrets out of the repo. Use `.env` and `direnv allow` for scoping.

