# Migration Execution Checklist — TDD Workflow

This checklist drives the implementation of `docs/migration_plan.md:1` using short, repeatable TDD cycles: write a failing test, make it pass, refactor, run regression tests, then proceed to the next failing test.

Conventions and Guardrails
- Test runner: prefer existing harnesses under `test/` (`scripts/run-tests.sh`, `test/run-all-tests.sh`).
- New tests: add in `test/` as `test-*.sh` or `*.ps1` mirroring current style (see `test/framework.sh:1`).
- Keep each cycle small; commit after green state.
- Best practices: avoid hardcoding repo paths in home-managed files; use detection and no-ops when dependencies are absent.
- Idempotence: every change must be safe to run repeatedly. Add tests that run apply/commands twice and expect no diffs.
- Linting: add shellcheck/shfmt checks for new shell files; keep implementation minimal to avoid technical debt.

---

## Phase 1 — Chezmoi as Single Source of Truth

1) Red: author minimal tests
- Add `test/test-chezmoi-templates.sh`:
  - Verifies chezmoi is invocable (`chezmoi --version`).
  - Asserts `chezmoi apply --source "$PWD" --dry-run` exits 0.
  - Idempotence: run `chezmoi apply --source "$PWD" --dry-run` twice; second run should show no planned changes.
  - Greps planned outputs for target files: `.zshrc`, `.bashrc`, `~/.gitignore_global`, `PowerShell/Microsoft.PowerShell_profile.ps1` (WSL may skip Windows profile with a conditional).
  - Checks planned contents include a direnv hook line for zsh/bash.

2) Green: implement
- Create chezmoi templates per `docs/migration_plan.md` (dot_zshrc, dot_bashrc, dot_gitignore_global, PowerShell profile, etc.) with platform conditionals.
- Ensure direnv hook lines are present in templates.

3) Refactor
- Simplify duplicated PATH/direnv logic into template partials if needed.

4) Regression
- Run: `bash scripts/run-tests.sh` and `bash test/run-all-tests.sh`.
 - Verify `chezmoi diff --source "$PWD"` reports no changes after a second apply.

Next failing test: template content accuracy and platform branching.

---

## Phase 2 — Direnv Standardization

1) Red: author tests
- Extend `test/test-chezmoi-templates.sh` or add `test/test-direnv-hooks.sh` to assert rc files include:
  - `eval "$(direnv hook zsh)"` for zsh; `bash` for bash.
  - PowerShell: `direnv hook pwsh` appears when `direnv` exists.
- Add repo-level test `test/test-direnv-policy.sh` to assert `.envrc` template includes `use mise` then `dotenv`.
 - Lint: shellcheck for newly added templates if they include shell code.

2) Green: implement
- Update templates to include explicit direnv hooks.
- Update `.envrc` template/example to `use mise` then `dotenv`.

3) Refactor
- Consolidate shared hook logic into a minimal common snippet if appropriate.

4) Regression
- Run full suite.
 - Verify running templates twice remains a no-op (`chezmoi apply --dry-run`).


## Phase 3 — Adopt Mise; Deprecate Volta Wiring

1) Red: author tests
- Add `test/test-mise-adoption.sh`:
  - Fails if Volta-specific PATH is injected by default in new shells.
  - Passes if a chezmoi-managed `~/.mise.toml` (or `.tool-versions`) is present after apply.
  - If `mise` exists, `mise install --dry-run` exits 0.
 - Idempotence: `mise install` can be re-run without side effects.

2) Green: implement
- Add `dot_mise.toml` template with commented defaults.
- Remove Volta PATH injection from templated rc files; keep optional example in docs only.

3) Refactor
- Ensure PATH logic is centralized and conditional by platform.

4) Regression
- Run full suite.
 - Run `mise install` twice; second run should be a no-op.

---

## Phase 4 — SSH Agent Bridge Integration via Templates

1) Red: author tests
- Add/extend `test/test-ssh-agent-bridge.sh` to also check rc files:
  - `SSH_AUTH_SOCK` exported or validated when bridge is present.
  - A helper function or message points to `ssh-agent-bridge/preflight.sh`.
 - Ensure no failure if bridge tools are absent (no hard dependency).

2) Green: implement
- Add minimal `SSH_AUTH_SOCK` export and health-check hook in templated rc files with WSL detection.

3) Refactor
- Keep the logic minimal; defer heavy lifting to `ssh-agent-bridge/` scripts.

4) Regression
- Run full suite.
 - Validate shells start cleanly without the bridge (best-effort pattern).

* use context7

###### phases 1, 2, 3, and 4 complete ######
---

## Phase 5 — Global Justfile

1) Red: author tests
- Add `test/test-global-justfile.sh`:
  - After `chezmoi apply --dry-run`, planned file includes `~/.justfile` with `bootstrap`, `lint`, `format`.
  - `bootstrap` includes `chezmoi apply` then `mise install`.
 - Idempotence: running `just bootstrap` twice produces no changes after the first run.

2) Green: implement
- Add `dot_justfile` template with required recipes.

3) Refactor
- Align recipe names/descriptions with repo-local `justfile` conventions.

4) Regression
- Run full suite.
 - Verify `chezmoi diff` remains empty after bootstrap.

* use context7
---

## Phase 6 — Filesystem & PATH via Templates

1) Red: author tests
- Add `test/test-path-config.sh`:
  - New shell PATH contains Projects folder once (no duplicates).
  - Platform-specific entries appear only on the correct OS/WSL.
 - Verify re-sourcing rc files does not duplicate PATH entries.

2) Green: implement
- Move PATH logic into templates with per-platform conditionals.

3) Refactor
- Remove redundant PATH mutations in repo runtime scripts where templates guarantee setup.

4) Regression
- Run full suite.
 - Source rc files multiple times; PATH remains stable.

* use context7
---

## Phase 7 — Security Hardening

1) Red: author tests
- Add `test/test-gitignore-global.sh`:
  - Asserts a chezmoi-managed `~/.gitignore_global` contains `.env`, `.envrc`, `.envrc.local`, `.direnv/`.
  - Optionally checks `git config --global core.excludesfile` is set (non-destructive read).
 - Ensure appending the same entries twice is a no-op (managed by chezmoi template).

2) Green: implement
- Add `dot_gitignore_global` and a one-time bootstrap note or script to set `core.excludesfile`.

3) Refactor
- Keep policy concise and well-commented.

4) Regression
- Run full suite.
 - Confirm `git config --global core.excludesfile` remains unchanged after re-apply.

---

## Phase 8 — Cleanup & Deprecations

1) Red: author tests
- Add `test/test-no-deprecated-loaders.sh`:
  - Fails if default shell init sources `scripts/load_env.sh` or other deprecated loaders.
 - Ensure no warnings are emitted on shell startup from deprecated scripts.

2) Green: implement
- Remove deprecated references from templates; keep `lib/env-loader.sh` only for script use.

3) Refactor
- Update docs to reflect the new bootstrap-first approach with chezmoi.

4) Regression
- Run full suite.
 - Open a login and interactive shell in CI to ensure no startup warnings.

* use context7
---

## Continuous Regression

- After each green step, run:
  - `bash scripts/run-tests.sh`
  - `bash test/run-all-tests.sh` (if applicable in environment)
- Periodically test in clean WSL profile and Windows user profile for parity.
 - Add an idempotence gate: run `chezmoi apply --source "$PWD" --dry-run` twice; second must be a no-op.
 - Keep PRs small and focused; avoid opportunistic refactors that add debt.
