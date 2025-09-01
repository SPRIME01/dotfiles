# direnv Setup (How‑To)

This repo already wires in optional direnv hooks for Bash, Zsh, and PowerShell. This guide gives you a robust, security‑minded setup that scopes secrets to this repository while improving day‑to‑day ergonomics.

## Install

- Linux/macOS: `sudo apt install direnv` or `brew install direnv`
- Windows (PowerShell 7): `scoop install direnv` or `choco install direnv -y`

The repo’s shell loader auto‑hooks direnv when present. No extra lines in your rc files are required.

## Recommended Layout

- `.env` – private variables for this repo (gitignored)
- `mcp/.env` – optional MCP‑related secrets (gitignored)
- `.envrc` – direnv policy for this repo (committed)
- `.envrc.local` – personal tweaks (gitignored), e.g. temporary overrides

Create a starter `.envrc` from the template:

```bash
cp .envrc.example .envrc
# edit if needed
direnv allow
```

The template does the following:

- Uses `dotenv_if_exists` to load `.env` and `mcp/.env` without executing code
- Watches those files and auto‑reloads
- Applies `umask 077` so new files are private by default
- Adds `scripts/` and `tools/` to `PATH` only when you’re in this repo
- Stays quiet by default (`DIRENV_LOG_FORMAT=""`), with helpers to toggle

## Security Notes

- Secrets live in `.env`/`mcp/.env` which are already gitignored.
- direnv scopes variables to this directory; leaving it restores your previous environment.
- Consider a global policy file to harden loading further.

## Optional: Global Policy (`~/.config/direnv/direnvrc`)

Drop the provided example in place and adjust:

```bash
mkdir -p ~/.config/direnv
cp docs/reference/direnvrc.example ~/.config/direnv/direnvrc
```

The template adds helpers to:

- Warn if dotenv files aren’t `chmod 600`
- Provide a `dotenv_strict` loader that refuses risky files
- Offer small utilities for PATH and toolchain setup

## Interop with Existing Loader

The shell startup already imports `.env` globally via `lib/env-loader.sh`. You can:

- Keep it as‑is (direnv simply re‑applies values when you’re in this repo), or
- Prefer direnv‑only secrets by setting before launching your shell:

```bash
export DOTFILES_SKIP_SECRET_FILES=1         # skip loading .env and mcp/.env globally
# or granular:
export DOTFILES_SKIP_ENV_FILE=1             # skip only .env
export DOTFILES_SKIP_MCP_ENV=1              # skip only mcp/.env
```

With these flags, secrets are only loaded when direnv activates in this directory.

## Quick Commands

- `direnv allow` – trust/enable `.envrc`
- `direnv deny` – revoke trust
- `direnv reload` – re‑evaluate after edits
- `direnv_status` – helper already available in bash/zsh

That’s it—consistent, per‑repo envs with safer scoping and minimal noise.

## Dotenv Formatting (Important)

When using `dotenv_if_exists`, values must follow POSIX dotenv rules:

- Use `KEY=value` with no spaces around `=`.
- Quote values that contain spaces or special characters:
  - `NAME="Jane Doe"`
  - `TOKEN='abc#123'`
- Do not prefix with `export`.
- Comments start with `#` and should be on their own lines.

Troubleshooting example:

- Bad: `BAR=baz value` → Good: `BAR="baz value"`
- After fixing, run `direnv reload` (or `direnv allow` if `.envrc` changed).
