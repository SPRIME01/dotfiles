# Contributing Guidelines

Thank you for helping improve these dotfiles. Consistency and idempotency are top priorities.

## Core Principles
- Idempotent scripts: safe to re-run any time
- Minimal external dependencies; detect & install only when necessary
- Cross-shell parity (Bash/Zsh + PowerShell where applicable)
- Clear separation of concerns: orchestration vs. component logic
- Document new variables and decisions (env-schema & ADRs)

## Workflow
1. Create a feature branch: `feat/<short-topic>` or `fix/<issue>`
2. Run tests & lint before committing: `just lint` and `just test`
3. Open PR referencing any debt items addressed
4. Ensure CI passes

## Commit Message Conventions
Format: `<type>: <concise summary>`
Types:
- feat: new user-facing capability
- fix: bug fix
- chore: tooling, ci, infra changes
- docs: documentation only
- refactor: code restructuring without behavior change
- test: add or adjust tests
- perf: performance improvement

## Script Standards
All shell scripts:
```
#!/usr/bin/env bash
set -euo pipefail
```
Add the documented header block for new scripts (see docs/TECHNICAL_DEBT_REPORT.md — Appendix A: Proposed Script Header Template).

## Adding Components
1. Implement script under `scripts/` or appropriate directory
2. Add entry to `components.yaml`
3. Provide/update tests when risk is medium/high
4. Update documentation if environment variables or behaviors change

## Environment Variables
Document new variables in `docs/env-schema.md` with description and default.

## Tests
- Add scenario tests for provisioning behavior touching file system or idempotency
- Prefer simple, fast, isolated tests (no network if avoidable)

## ADRs
When making a significant architectural decision, add an ADR in `docs/adr/` using template.

## Style
- Use lowercase-with-hyphens for script filenames
- Functions in bash use snake_case
- Keep lines <= 120 chars where practical
- See `docs/naming.md` for detailed conventions (scripts, env vars, components)

## Lint & Formatting
Run `just lint` before pushing. Format shell code with `shfmt -w` if needed.

## Questions
Open a GitHub issue with context and reproduction steps.
