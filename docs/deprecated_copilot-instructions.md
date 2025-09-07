# DEPRECATED — Copilot Coding Agent Onboarding for dotfiles

> This document is retained for historical reference. The canonical, maintained guide lives at:
> .github/copilot-instructions.md

This repository contains portable shell configuration and setup tooling for Bash/Zsh (Linux/WSL2) and PowerShell 7 (Windows). It centralizes environment variables, aliases/functions, prompt themes, VS Code settings, MCP (Model Context Protocol) configuration, and remote/SSH integration.

Trust these instructions first. Only search if a step errors or required info is missing.

## What this repo is
- Purpose: Developer dotfiles to bootstrap and maintain a consistent shell and editor setup across Linux/WSL2/macOS and Windows (PowerShell 7).
- Languages/stack: Bash/sh, Zsh, PowerShell, JSON. No external build system. Optional Justfile task runner.
- Scope: Shell profiles, helper scripts, VS Code settings, WSL2/Windows integration, MCP env.
- Size/shape: Flat scripts under repo root and scripts/, install/, test/, PowerShell/, zsh/, docs/, mcp/.

## Quick start (safe defaults)
- Always run tests before and after changes:
  - Linux/WSL2: `bash scripts/run-tests.sh`
  - PowerShell tests run automatically if `pwsh` is on PATH; otherwise they’re skipped.
- Bootstrap only when needed (e.g., first install or after significant changes): `./bootstrap.sh` (Linux/WSL2/macOS) or `pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1` (Windows).
- VS Code settings install: `bash install/vscode.sh` (also invoked by bootstrap).
- Update workflow: `bash update.sh` (auto-stashes local changes, pulls, reapplies bootstrap, pops stash).
 - direnv: repo includes `.envrc` and hooks for Bash/Zsh/PowerShell. Enable once with `direnv allow` in the repo root. Use `.envrc.local` for personal tweaks.

## Runtimes and tools
- Bash/Zsh (Linux/WSL2/macOS). Default user shell may be zsh.
- PowerShell 7 (pwsh) optional; tests auto-skip if not installed.
- Oh My Posh and Powerlevel10k used for prompts (auto-installed by bootstrap if missing).
- Optional: Just (task runner) for convenience targets (`just --list`). Not required for CI or tests.
- Optional: direnv for per-repo env scoping (installed via `just install-direnv`).
- Optional: Vault (CLI/Agent) for secret delivery; see `docs/how-to/vault.md` and Just tasks below.

## Build/validate/run matrix
There is no compile step; “build” means validating scripts/configs.

- Bootstrap (idempotent):
  - Linux/WSL2/macOS: `./bootstrap.sh`
    - Preconditions: curl, standard Unix tools. Network required to fetch oh-my-posh on first run.
    - Postconditions: dotfiles linked to home, oh-my-posh installed, Zsh set up (Linux/WSL2), MCP and VS Code config checked/installed.
  - Windows: `pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1`
    - Installs modules, links PowerShell profile, configures theme.

- Tests:
  - Single entry point: `bash scripts/run-tests.sh`
    - Runs shell tests under `test/*.sh` and, if available, PowerShell tests under `test/*.ps1`.
    - Exit code 0 on success; non‑zero on failure. Use this as the acceptance check before opening a PR.
  - Known behavior: If `pwsh` is not installed, PowerShell tests are skipped with a warning and the suite still passes.

- VS Code integration:
  - Install/merge settings: `bash install/vscode.sh`
  - Uses `jq` for JSON merge. If missing, script will attempt to install it on Linux/WSL; otherwise it falls back to copying base settings.

- Update:
  - `bash update.sh` always stashes uncommitted changes first, pulls `main`, runs `bootstrap.sh`, then pops the stash. Prefer this over raw `git pull` for users with local edits.

- direnv / env loading:
  - Global loader is `lib/env-loader.sh` (used by `.shell_common.sh`). To avoid globally exporting secrets (prefer per-repo via direnv), set these before starting shells:
    - `export DOTFILES_SKIP_SECRET_FILES=1` (skip both `.env` and `mcp/.env`)
    - or granular: `DOTFILES_SKIP_ENV_FILE=1`, `DOTFILES_SKIP_MCP_ENV=1`
  - Repo-scoped env: `.envrc` loads `.env`, `mcp/.env`, and optionally a Vault Agent sink (`$HOME/.cache/vault/dotfiles.env` by default). Personal overrides live in `.envrc.local`.

## Common errors and mitigations
- git pull divergence: prefer rebase; set local default with `git config pull.rebase true` or use `bash update.sh` which handles stashing before pulling.
- Missing jq: `install/vscode.sh` will try to install on Linux/WSL (apt/yum/pacman). On macOS, ensure Homebrew is installed or preinstall `jq`.
- No pwsh on Linux/WSL: PowerShell tests are skipped; this does not indicate failure.
- WSL/Windows paths: `install/vscode.sh` resolves Windows user via PowerShell; in unusual environments, pass explicit HOME/APPDATA.

## Project layout map (edit hotspots)
- Root files: `.bashrc`, `.zshrc`, `.p10k.zsh`, `.shell_common.sh`, `.shell_functions.sh`, `.shell_theme_common.ps1`, `.envrc`, `.envrc.example`, `.envrc.vault.example`, `bootstrap.sh/.ps1`, `install.sh/.ps1`, `update.sh/.ps1`, `justfile`, `README.md`.
- Bash/Zsh helpers: `scripts/` (e.g., `load_env.sh`, `setup-wizard.sh`, `setup-ssh-agent-bridge.sh`, WSL2 and Windows integration scripts).
- PowerShell: `PowerShell/` with `Microsoft.PowerShell_profile.ps1`, `Utils/Load-Env.ps1`, `Modules/Aliases/*` (functions and `Aliases.psm1` aggregator), `Themes/*.omp.json`.
- VS Code: `.config/Code/User/settings.json` + `settings.{linux,windows,darwin,wsl}.json`; installer at `install/vscode.sh`; tests at `test/test-vscode-integration.sh`.
- MCP: `mcp/` with `.env` (user-supplied), `servers.json`, helper scripts and docs.
- Tests: `test/` — shell and PowerShell tests; runner at `scripts/run-tests.sh`.
- Docs: `docs/*.md` covering environment, SSH agent, WSL integration, remote access, PowerShell 7 setup, etc.
  - direnv: `docs/how-to/direnv.md`; Vault: `docs/how-to/vault.md`; env schema: `docs/reference/env-schema.md`.

## Pre-PR checklist (what CI would enforce)
There is no GitHub Actions workflow yet; emulate CI locally:
1) Run: `bash scripts/run-tests.sh` → must exit 0.
2) If you changed VS Code settings or merging logic, run the VS Code tests alone to inspect output: `bash test/test-vscode-integration.sh`.
3) If you modified PowerShell files and have pwsh installed, re-run tests to include PS validation. On Windows, also launch a fresh pwsh to load the profile.
4) For WSL/Windows integration changes, use the Just tasks to exercise flows: `just setup-wsl2-remote`, `just setup-ssh-agent-windows`, `just setup-projects` (safe to re-run).

## Conventions and guardrails
- Shell scripts use `set -euo pipefail`; keep it and handle unset vars explicitly.
- Prefer idempotent, re-runnable installers; check for existence before creating or installing.
- Don’t hardcode Windows usernames or distro names; when needed, obtain via `cmd.exe`/`pwsh.exe`/env vars as existing scripts do.
- Keep user secrets out of VCS: `.env` and `mcp/.env` are user-provided and must not be committed.
- Maintain cross-shell parity: shared logic in `.shell_common.sh` and `PowerShell/Utils/Load-Env.ps1` should stay feature-aligned.

## Typical workflows (validated)
- Fresh Linux/WSL2 setup:
  1) `./bootstrap.sh`
  2) Optional: `just setup` for guided flow; or `bash install/vscode.sh` to (re)apply editor settings.
  3) `bash scripts/run-tests.sh` → expect “All tests passed” (PS tests may be skipped if no pwsh).

- Modify env loading:
  1) Prefer `.envrc`/`.envrc.local` for repo-scoped env. Global: edit `lib/env-loader.sh` (and PS equivalent) only for loader logic.
  2) Use `DOTFILES_SKIP_SECRET_FILES=1` to avoid global secrets; rely on direnv to load `.env` and Vault sink when in the repo.
  3) `bash scripts/run-tests.sh` to validate.

- Update VS Code settings structure:
  1) Edit `.config/Code/User/settings*.json` and `install/vscode.sh` if merge logic changes.
  2) `bash test/test-vscode-integration.sh`.

## Notes on timing and external deps
- First bootstrap may download oh-my-posh; allow ~10–60s depending on network.
- `install/vscode.sh` may install `jq` on Linux/WSL; this can add ~10–120s depending on package manager and cache.
 - direnv enables instantly; first `direnv allow` writes a trust file. Vault Agent adds a background process; start/stop with Just helpers.

## Just tasks (direnv/Vault)
- `just install-direnv` — install direnv
- `just vault-agent-example` — copy example agent config to `/tmp/agent.hcl`
- `just vault-agent-run` — run agent with env vars (requires `VAULT_ADDR`) and writes to `$HOME/.cache/vault/dotfiles.env` by default
- `just vault-agent-run-demo` — run agent with demo defaults (still requires `VAULT_ADDR`)


## When to search
Follow these instructions as source of truth. Search the codebase only if:
- A referenced file path changes, or
- A command exits non‑zero and the mitigation above doesn’t apply, or
- You’re adding a new subsystem not covered here.

That’s it—run tests, keep scripts idempotent, avoid committing secrets, and your PRs should sail through.
