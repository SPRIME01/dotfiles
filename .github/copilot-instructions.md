# Copilot Coding Agent Onboarding — dotfiles

Trust this document first. Only search the repo if an instruction here is missing or fails.

## What this repo is
- Purpose: Portable, idempotent dotfiles to provision and maintain a consistent dev shell across Linux/WSL2/macOS (Bash/Zsh) and Windows (PowerShell 7). Includes prompt themes (Oh My Posh/Powerlevel10k), shared aliases/functions, VS Code settings integration, WSL↔Windows helpers, and MCP config.
- Type/stack: Shell scripts (bash/sh/zsh) + PowerShell + JSON. No compile step. Optional Justfile tasks.
- Size/layout: Scripts and configs in the repo root and subfolders: `scripts/`, `lib/`, `shell/`, `PowerShell/`, `zsh/`, `ssh-agent-bridge/`, `mcp/`, `test/`, `docs/`, `.github/`.

## Key paths and entry points
- Bootstrap: `bootstrap.sh` (Linux/WSL2/macOS), `bootstrap.ps1` (Windows)
- Tests (single entry): `scripts/run-tests.sh` → runs `test/run-all-tests.sh`
- Lint/format check: `tools/lint.sh`
- Task runner: `justfile` (local), `dot_justfile` (global template managed by chezmoi)
- Env loader & common libs: `lib/*.sh` (env-loader, platform-detection, validation, log, state-management)
- Shell config/templates: `.bashrc`, `.zshrc`, `.p10k.zsh`, `.shell_common.sh`, `.shell_functions.sh`, PowerShell profile/theme in `PowerShell/`
- VS Code integration: `.config/Code/User/settings*.json` and installer script (see tests); summary in `VSCODE_INTEGRATION_SUMMARY.md`
- SSH agent bridge: `ssh-agent-bridge/*` with just recipes in `justfile`
- MCP: `mcp/servers.json`, helper scripts, and user-provided `mcp/.env`

## Build/validate/run matrix (tested sequences)
There is no compile step; “build” means lint + tests. Always run tests before opening a PR.

- Lint (safe, fast)
  - Command: `bash tools/lint.sh`
  - Preconditions: none (auto-skips if shellcheck/shfmt are missing). On Linux CI, installs both.
  - Notes: Produces warnings/errors but won’t fail if both tools are absent.

- Tests (authoritative acceptance)
  - Command: `bash scripts/run-tests.sh`
  - What it does: runs all `test/*.sh`, and `test/*.ps1` if `pwsh` is available. Prints a summary and exits non-zero on failures.
  - Observed on 2025-09-05: 24/27 passed, 3 skipped (oh-my-posh installer stability, WSL-only flows). Suite ended SUCCESS.

- Bootstrap (idempotent provisioning)
  - Linux/WSL2/macOS: `./bootstrap.sh`
    - Preconditions: curl, network (first run) for Oh My Posh. Standard coreutils.
    - Postconditions: dotfiles linked, Oh My Posh installed (or skipped), Zsh configured, env loaders active.
  - Windows: `pwsh -NoProfile -ExecutionPolicy Bypass -File ./bootstrap.ps1`
    - Postconditions: profile linked, modules/themes installed.

- VS Code settings
  - Refer to `VSCODE_INTEGRATION_SUMMARY.md` and `test/test-vscode-integration.sh`.
  - Known: JSON validity checks pass; three subtests may fail if the installer script is not flagged executable or platform detection isn’t available. These are not required for CI success but are good to fix in follow-ups.

- Doctor/diagnostics
  - `bash scripts/doctor.sh [--quick] [--verbose] [--strict]`
  - Default: informational (exit 0 even with warnings). Use `--strict` to fail on issues.
  - `bash scripts/diagnose-shell.sh` prints startup findings; always safe.

- Update workflow
  - Command: `bash update.sh`
  - Behavior: stashes uncommitted changes, pulls `main`, re-runs bootstrap, pops stash; safer than raw `git pull`.

- Just tasks (optional)
  - List tasks: `just` (shows sections; SSH bridge commands pinned at top)
  - Common: `just test` (runs tests), `just lint` (tools/lint.sh), `just setup` (wizard), `just setup-windows-integration`, `just install-direnv`, and SSH bridge helpers (`ssh-bridge-*`). Many require WSL/Windows context—see printed guards.

## CI and pre-PR checks
- GitHub Actions: `.github/workflows/ci.yml` runs on push/PR for `ubuntu-latest` and `macos-latest`:
  - Installs shellcheck + shfmt, runs `bash tools/lint.sh` and `bash scripts/run-tests.sh`.
- `.github/workflows/test.yml`: runs tests on `ubuntu-latest` with matrix of `bash` and `zsh`.
- Local dev rule of thumb:
  1) Always run `bash scripts/run-tests.sh` before committing.
  2) If you touched shell scripts, run `bash tools/lint.sh`.
  3) For WSL/Windows flows, use the guarded `just` recipes to smoke test.

## Required/optional dependencies
- Required for most flows: bash, coreutils, curl. Tests assume a POSIX-ish shell.
- Optional: zsh (some CI matrix), PowerShell 7 (enables PS tests, auto-skipped if absent), shellcheck, shfmt, direnv, jq (for VS Code installer), Git.
- Fonts/themes (prompt): installed or checked by bootstrap; first run may download binaries (allow 10–60s on slow networks).

## Editing guide — hotspots and conventions
- Shared logic: `.shell_common.sh`, `.shell_functions.sh`, `lib/*.sh` → keep idempotent; scripts use `set -euo pipefail`.
- PowerShell: `PowerShell/Modules/Aliases/*`, `PowerShell/Microsoft.PowerShell_profile.ps1`, `PowerShell/Themes/*.omp.json`.
- Templates: `dot_*.tmpl` files (chezmoi managed) for shell and path configuration.
- SSH bridge: `ssh-agent-bridge/*.sh` and Windows PowerShell helpers; invoked via `just ssh-bridge-*`.
- Tests: add new `test/test-*.sh` or `test/*.ps1` and they will run automatically via the unified runner.

## Known pitfalls and mitigations
- Lint failures: If `shfmt` missing locally, lint prints a warning and continues; CI ensures the tools exist.
- Doctor script exit: Defaults to success; add `--strict` when you need a failing exit for gating.
- VS Code installer tests: May fail certain checks on platforms without the expected environment. Use the test log to see which subcheck failed and run in an OS-appropriate shell.
- WSL-specific tasks: Commands that mention `powershell.exe` must be run from WSL; they guard with `WSL_DISTRO_NAME`.

## Fast reference
- Lint: `bash tools/lint.sh`
- Tests: `bash scripts/run-tests.sh`
- Bootstrap: `./bootstrap.sh` (Linux/macOS) or `pwsh -NoProfile -File ./bootstrap.ps1` (Windows)
- Update: `bash update.sh`
- Doctor: `bash scripts/doctor.sh --strict` (optional gating)
- Tasks: `just` (optional; see `justfile`)

## Root files index (selected)
- Root: `README.md`, `CONTRIBUTING.md`, `justfile`, `bootstrap.sh/.ps1`, `install.sh/.ps1`, `update.sh/.ps1`, `.bashrc`, `.zshrc`, `.p10k.zsh`, `.shell_common.sh`, `.shell_functions.sh`, `.envrc*`, `VSCODE_INTEGRATION_SUMMARY.md`, `vscode-extensions.txt`
- Folders:
  - `.github/` → Actions (`ci.yml`, `test.yml`), this file
  - `scripts/` → setup/diagnostics/wizards, `run-tests.sh`
  - `test/` → scenario tests plus runner
  - `tools/` → `lint.sh`, health & profiling helpers
  - `lib/` → env/validation/platform libs
  - `PowerShell/` → profile, themes, modules
  - `ssh-agent-bridge/` → WSL↔Windows agent tooling
  - `mcp/` → servers, env, helpers
  - `docs/` → how-to, reference, migration specs

Follow these steps exactly. If something deviates, prefer running the unified tests to validate behavior rather than broad searches. Only search when a path or command here proves incorrect in your environment.
