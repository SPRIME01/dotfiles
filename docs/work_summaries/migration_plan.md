# Migration Plan — Align Dotfiles to Integrated Developer Environment Spec

This plan migrates the current dotfiles project to conform to the spec in `docs/migration_spec.md:1` while preserving existing functionality and minimizing disruption.

Scope covers Linux/WSL shells (zsh, bash) and Windows PowerShell, with a focus on unifying configuration under chezmoi, adopting mise for tool versions, standardizing direnv usage, and formalizing the SSH agent bridge setup.

---

## Goals

- Single source of truth via chezmoi for user dotfiles across Windows + WSL.
- Consistent project-scoped environments via direnv, with secure defaults.
- Tool/runtime management via mise; deprecate Volta-specific wiring.
- Unified SSH agent bridge using npiperelay, surfaced via templated config.
- Standardized task runner with global `~/.justfile` and per-project justfiles.
- Clear bootstrap workflow for new machines and new projects.

---

## Current State Summary

- Shells and UX
  - Zsh + Oh My Zsh with direnv plugin enabled (`zsh/plugins.zsh:1`).
  - Bash configured with common settings (`shell/bash/config.sh:1`).
  - PowerShell 7 profile with Oh My Posh themes and PSReadLine (`shell/powershell/config.ps1:1`, `PowerShell/Themes/...`).

- Environment loading and direnv
  - Centralized direnv hook for bash/zsh (`shell/common/direnv.sh:1`).
  - Repo-level `.envrc` with secure defaults and dotenv loaders (`.envrc:1`).
  - How-to docs available (`docs/how-to/direnv.md:1`).

- SSH agent bridge
  - Full implementation exists under `ssh-agent-bridge/` with install, preflight, fix scripts and Just wrappers (`justfile:331`, `ssh-agent-bridge/install-wsl-agent-bridge.sh:1`).
  - Some scripts still manipulate `SSH_AUTH_SOCK` dynamically; not yet templated via chezmoi.

- Tool/version management
  - No mise adoption yet. Volta is referenced in multiple places (`zsh/path.zsh:15`, `.envrc:33`, `lib/env-loader.sh:86`).
  - No `.mise.toml`/`.tool-versions` patterns present.

- Task automation
  - A project-local `justfile` exists with many repo ops (`justfile:1`).
  - No global `~/.justfile` managed for cross-repo tasks.

- Configuration management
  - Project is not a chezmoi repo. No templates or `dot_*`/`.tmpl` structure.

- Security
  - Secure direnv defaults in `.envrc`; guidance for `.envrc.local` and Vault integration (`docs/how-to/vault.md:48`).
  - No global gitignore for `.env`/`.envrc` yet.

---

## Target Architecture (per spec)

1) Shell Configuration
- Zsh (primary WSL) with Oh My Zsh + explicit direnv hook in rc file.
- Bash (fallback) with lightweight direnv hook in rc file.
- PowerShell (Windows) with Oh My Posh and direnv hook for pwsh.

2) Configuration Management — Chezmoi as SSoT
- Manage `.zshrc`, `.bashrc`, `$PROFILE`, `.gitconfig`, `.ssh/config`, `.gitignore_global`, `~/.justfile`, and base `.mise.toml` via chezmoi templates with per-platform conditionals.

3) SSH Management — Unified Agent Architecture
- Use `ssh-agent-bridge/` and `npiperelay.exe` with `SSH_AUTH_SOCK` exported via chezmoi-managed shell templates.

4) Environment & Context — Direnv
- Explicit hook lines in templated rc files; repo/project `.envrc` pattern uses `use mise` and `dotenv`.

5) Runtime & Tool Management — Mise
- Adopt `.mise.toml` (or `.tool-versions`) for versions; wire into direnv via `use mise`.

6) Task Automation — Just
- Global `~/.justfile` (chezmoi-managed) for common tasks (bootstrap, lint, format).
- Per-project `justfile` stays local with repo-specific tasks.

7) Filesystem Architecture
- Default projects path in WSL; optional Windows link exposure (existing `scripts/setup-projects-idempotent.sh`).
- PATH adjustments via templates not ad-hoc scripts.

8) Security & Best Practices
- Global ignore for `.env`, `.envrc` via `~/.gitignore_global` template.
- Project-scoped env only via direnv.

9) Bootstrap Workflow
- New machines: install chezmoi, apply; then `mise install`, direnv hooks live, and SSH bridge setup.

---

## Migration Phases and Steps

Phase 0 — Preparation
- Create a `migration` branch for the work.
- Enable a side-by-side install path to validate without breaking current setup.

Phase 1 — Introduce Chezmoi SSoT
- Add chezmoi scaffolding and structure:
  - Create templates for: `dot_zshrc`, `dot_bashrc`, `dot_gitconfig`, `dot_ssh/config` (or `dot_ssh.tmpl`), `dot_gitignore_global`, `dot_justfile`, `PowerShell/profile` (Windows), and base `dot_mise.toml`.
  - Each template injects direnv hooks, PATH, and platform-specific logic using chezmoi conditionals.
- Implement a minimal bootstrap `install.sh` snippet that installs chezmoi and runs `chezmoi init --apply` for this repo.
- Acceptance:
  - Running `chezmoi apply` writes files to `$HOME` without errors on WSL and Windows.
  - Direnv hooks present in new rc files; shells start cleanly.

Phase 2 — Direnv Standardization
- Ensure `.envrc` starter aligns with spec: `use mise` then `dotenv`.
- Provide `docs/how-to/direnv.md` quickstart updates to reflect mise integration.
- Update `docs/reference/direnvrc.example` with `use mise` helpers.
- Acceptance:
  - New projects using the template activate `mise` toolchains on `direnv allow`.

Phase 3 — Adopt Mise; Deprecate Volta Wiring
- Add `dot_mise.toml` (chezmoi) with opinionated defaults and comments for Node/Python/Rust/Go.
- Remove Volta-specific PATH logic from templates and repo `.envrc` (keep compatibility notes in docs for manual transition if Volta is still installed).
- Add Just recipes for `mise install` in global `~/.justfile`.
- Acceptance:
  - `mise --version` detected and `mise install` runs from a fresh machine bootstrap.
  - No repo-managed Volta PATH in shell startup; usage notes documented.

Phase 4 — SSH Agent Bridge via Templates
- Keep `ssh-agent-bridge/` as the implementation of record.
- Add chezmoi-managed per-shell stanzas to export `SSH_AUTH_SOCK` and optionally source a small helper that verifies bridge status.
- Provide a `just ssh-bridge-*` delegation in the global justfile that forwards to repo scripts if repo is cloned, or prints guidance.
- Acceptance:
  - On WSL, after bridge install, shells expose a valid `SSH_AUTH_SOCK`.
  - `ssh-add -l` works (after keys present in Windows agent).

Phase 5 — Global Justfile
- Create `dot_justfile` with:
  - `bootstrap`: `chezmoi apply` then `mise install`.
  - `lint`/`format` placeholders (shellcheck/shfmt or ruff as examples).
  - `direnv-install` helper (existing recipe trimmed for global context).
- Keep repo-local `justfile` for repo ops (tests, bridge details, Windows helpers).
- Acceptance:
  - `just -f ~/.justfile bootstrap` works cross-platform.

Phase 6 — Filesystem & PATH via Templates
- Move PATH logic (Projects folder, tools) into templated rc files with platform branching.
- Keep `scripts/setup-projects-idempotent.sh` as an optional helper and link to it from docs.
- Acceptance:
  - Fresh shells show expected PATH entries; no duplication.

Phase 7 — Security Hardening
- Add `dot_gitignore_global` with at least:
  - `.env`
  - `.envrc`
  - `.envrc.local`
  - `.direnv/`
- Configure git to use it in a templated step or one-time bootstrap note.
- Acceptance:
  - `git config --global core.excludesfile` points to the new file.

Phase 8 — Cleanup & Deprecations
- Remove legacy env loaders where superseded by templated rc + direnv (`scripts/load_env.sh` warning already indicates direction; keep `lib/env-loader.sh` only if still needed for specific scripts).
- Update docs to reflect chezmoi-first approach; add a migration note for users.
- Acceptance:
  - Startup warnings removed; no references to deprecated loaders in default shell paths.

---

## Detailed Work Items (Checklist)

- Chezmoi
  - Initialize chezmoi structure; document install + `chezmoi init` flow.
  - Add templates: `dot_zshrc`, `dot_bashrc`, `dot_gitconfig`, `dot_ssh/config.tmpl`, `dot_gitignore_global`, `dot_justfile`, `dot_mise.toml`, PowerShell profile (Windows only).
  - Add platform conditionals to configure PATH, direnv hook, `SSH_AUTH_SOCK`.

- Direnv
  - Update `.envrc` template snippet to include `use mise` and `dotenv` in that order.
  - Refresh `docs/how-to/direnv.md` to reflect new model and security posture.

- Mise
  - Author a sensible `dot_mise.toml` with commented examples for Python (uv), Node, Go, Rust.
  - Add global `just` tasks: `bootstrap` (includes `mise install`).
  - Add docs on replacing Volta with mise.

- SSH bridge
  - Keep `ssh-agent-bridge/` unchanged for behavior; surface minimal `SSH_AUTH_SOCK` export in templates.
  - Add a health-check function in shells that calls `ssh-agent-bridge/preflight.sh` if present.

- Global justfile
  - Create `dot_justfile` for common tasks across machines.
  - Keep repo `justfile` for project maintenance and tests.

- Security
  - Add `dot_gitignore_global`; template command to set `core.excludesfile` if unset.

- Bootstrap
  - Provide an `install.sh` snippet: install chezmoi + apply this repo; include Windows notes.

- Cleanup
  - Remove Volta PATH injection from repo `.envrc` and shell path files.
  - Retire `scripts/load_env.sh`; ensure `lib/env-loader.sh` is only used by scripts that truly need it.

---

## Acceptance Criteria

- Chezmoi apply succeeds on both WSL and Windows (PowerShell profile deployed correctly).
- New shells (zsh, bash, pwsh) include direnv hooks and no deprecation warnings.
- `direnv allow` in a sample project activates mise-managed toolchains.
- `mise install` completes from a global `~/.justfile` bootstrap.
- SSH agent bridge works end-to-end (`ssh-add -l` shows keys from Windows agent in WSL).
- Global gitignore protects `.env`, `.envrc`, `.direnv/` across repos.
- Existing repo tests still pass: `scripts/run-tests.sh`, `test/run-all-tests.sh`.

---

## Rollout Plan

1) Land chezmoi templates and global justfile behind a feature branch.
2) Validate in a clean WSL distro and a Windows user profile.
3) Migrate personal machine(s) with backup of existing rc files.
4) Announce Volta deprecation; provide a short grace period.
5) Remove deprecated loaders and Volta wiring from default paths.

---

## Risks and Mitigations

- Shell startup regressions
  - Mitigation: keep templates minimal; enable verbose mode toggle for debugging; provide rollback instructions.

- SSH bridge installation variability
  - Mitigation: depend on existing `ssh-agent-bridge/` scripts; add explicit checks in templates and docs.

- Tooling differences (mise vs. prior managers)
  - Mitigation: provide clear docs for transitioning; keep optional compatibility notes in `.envrc.example`.

- Chezmoi on Windows path quirks
  - Mitigation: test with PowerShell 7; keep WSL-first logic minimal on Windows.

---

## Validation Steps

- Fresh environment checks
  - Bootstrap: `just -f ~/.justfile bootstrap` then open new shells.
  - Direnv: create a sample project with `.envrc` → `use mise` + `dotenv`; run `direnv allow`.
  - Mise: define versions in project `.mise.toml` and verify activation.
  - SSH: run `just ssh-bridge-preflight` in repo context and `ssh-add -l` from WSL.

- Repo test suite
  - Run `scripts/run-tests.sh`.
  - Run `test/run-all-tests.sh` where supported.

---

## Timeline (Rough)

- Week 1: Chezmoi scaffolding + direnv + global justfile.
- Week 2: Mise adoption + Volta deprecation content.
- Week 3: SSH bridge templating + validation across platforms.
- Week 4: Cleanup, docs, and rollout.

---

## Out of Scope (Now)

- Rewriting existing `ssh-agent-bridge/` logic — keep as-is; only surface via templates.
- Changing repo-specific Just tasks — keep local `justfile` primarily for repo maintenance.

---

## Appendix — File Mapping (Example)

- Zsh: chezmoi `dot_zshrc` → includes Oh My Zsh init + `eval "$(direnv hook zsh)"` + SSH bridge status.
- Bash: chezmoi `dot_bashrc` → `eval "$(direnv hook bash)"` + light PATH.
- PowerShell: chezmoi Windows profile → Oh My Posh + `direnv hook pwsh`.
- Git: `dot_gitconfig` + `dot_gitignore_global` (set via bootstrap if unset).
- SSH: `dot_ssh/config.tmpl` for common hosts / includes.
- Tools: `dot_mise.toml` with commented defaults.
- Tasks: `dot_justfile` with `bootstrap`, `lint`, `format`, `direnv-install`.

