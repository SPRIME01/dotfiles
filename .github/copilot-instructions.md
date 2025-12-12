# Copilot Coding Agent Onboarding — dotfiles

Trust this document first. Only search the repo if an instruction here is missing or fails.

## What this repo is

- **Purpose**: Portable, idempotent dotfiles for a consistent dev shell across Linux/WSL2/macOS (Bash/Zsh) and Windows (PowerShell 7). Includes Oh My Posh prompts, shared aliases, VS Code integration, WSL↔Windows synergy, secret management (SOPS), and Tailscale SSH.
- **Stack**: Shell scripts (bash/zsh) + PowerShell + JSON. No compile step. Justfile task runner.
- **Layout**: Root configs + `scripts/`, `lib/`, `shell/`, `PowerShell/`, `test/`, `docs/`, `mcp/`

## Key paths

| Purpose             | Path                                                  |
| ------------------- | ----------------------------------------------------- |
| Bootstrap (Unix)    | `bootstrap.sh`                                        |
| Bootstrap (Windows) | `bootstrap.ps1`                                       |
| Tests               | `bash scripts/run-tests.sh`                           |
| Lint                | `bash tools/lint.sh`                                  |
| Task runner         | `justfile`                                            |
| Env loading         | `lib/env-loader.sh` → `.shell_common.sh`              |
| PowerShell profile  | `PowerShell/Microsoft.PowerShell_profile.ps1`         |
| Secret management   | `.sops.yaml`, `just secrets-*`                        |
| Remote access       | `scripts/setup-wsl2-remote-access.sh` (Tailscale SSH) |

## Developer workflow

```bash
# Before committing
bash scripts/run-tests.sh    # Must pass: 20+ tests
bash tools/lint.sh           # Shellcheck + shfmt

# For WSL/Windows integration (run from WSL)
just setup-pwsh7             # Link PowerShell profile to Windows
just install-tailscale       # Set up Tailscale SSH

# Diagnostics
bash scripts/doctor.sh --verbose
```

## Architecture patterns

### Shell initialization flow

```
.bashrc/.zshrc → .shell_common.sh → lib/env-loader.sh
                                  → shell/loader.sh (modular configs)
```

### PowerShell ↔ WSL2 synergy

- Windows profile sources from `\\wsl.localhost\<distro>\home\<user>\dotfiles\`
- Shared aliases: `projects`, `dotfiles`, `cddot`, `dotgit`
- `wslcode` / `wslcd` for navigating WSL paths from Windows

### Secret management

```bash
just secrets-edit            # Edit encrypted .secrets.json
just secrets-add KEY         # Add a secret
just secrets-decrypt         # Export to .env (gitignored)
```

## Conventions

### Shell scripts

- Always use `set -euo pipefail`
- Source `lib/env-loader.sh` for environment loading
- Check `${WSL_DISTRO_NAME:-}` before WSL-specific code
- Tests go in `test/test-*.sh` (auto-discovered by runner)

### PowerShell

- Add functions to `PowerShell/Modules/Aliases/*.ps1`
- Run `updatealiases` to regenerate lazy-loading wrappers
- Use `$env:DOTFILES_ROOT` and `$env:PROJECTS_ROOT`

### API keys / secrets

- Never commit `.env` files (gitignored)
- Use SOPS encryption: `just secrets-*` recipes
- Validation is opt-in: `DOTFILES_REQUIRE_API_KEYS=1`

## CI/CD

- **GitHub Actions**: `.github/workflows/ci.yml`
- Runs on `ubuntu-latest` + `macos-latest`
- Steps: Install shellcheck/shfmt → lint → test

## Common tasks

| Task             | Command                       |
| ---------------- | ----------------------------- |
| Run tests        | `bash scripts/run-tests.sh`   |
| Lint scripts     | `bash tools/lint.sh`          |
| Update from main | `bash update.sh`              |
| Setup wizard     | `just setup`                  |
| PowerShell setup | `just setup-pwsh7` (from WSL) |
| Remote access    | `just install-tailscale`      |

## Testing patterns

- Test framework: `test/framework.sh` with `test_assert*` helpers
- Test files: `test/test-*.sh` (shell), `test/*.ps1` (PowerShell)
- Skip tests with: `echo "SKIP: reason"; exit 0`

## Known pitfalls

- **Lint on macOS**: Install shellcheck/shfmt via Homebrew first
- **PowerShell tests**: Skipped if `pwsh` unavailable (expected in Linux CI)
- **WSL recipes**: Must be run from WSL, not native Windows terminal
- **Zsh syntax in shellcheck**: Use `# shellcheck disable=SC2296` for `${(%):-%x}`

## File index (key files)

- **Root**: `.shell_common.sh`, `.shell_functions.sh`, `justfile`, `bootstrap.sh/.ps1`
- **lib/**: `env-loader.sh`, `validation.sh`, `platform-detection.sh`
- **PowerShell/**: `Microsoft.PowerShell_profile.ps1`, `Modules/Aliases/*.ps1`
- **scripts/**: `setup-pwsh7.sh`, `setup-wsl2-remote-access.sh`, `doctor.sh`
- **test/**: `framework.sh`, `run-all-tests.sh`, `test-*.sh`
