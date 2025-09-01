# AI Index

Concise, high-signal reference for automated agents interacting with this repository.

## Core Purpose
Cross-shell (Bash/Zsh/PowerShell) developer environment bootstrap: prompts, themes (oh-my-posh, p10k), VS Code settings merge, WSL ↔ Windows integration, MCP configuration, SSH agent bridging, remote dev setup.

## Primary Entry Scripts

| Area | Script | Role |
|------|--------|------|
| Unified Setup | `scripts/setup-wizard.sh` | Interactive, state-aware installer |
| Bootstrap | `bootstrap.sh` / `bootstrap.ps1` | Core symlink + env setup |
| Dependency | `scripts/install-dependencies.sh` | Safe install socat & openssh client/server |
| Prompt Tool | `scripts/install-oh-my-posh.sh` | Pinned oh-my-posh install |
| Projects | `scripts/setup-projects-idempotent.sh` | Idempotent projects dir & Windows link |
| Remote Dev | `scripts/setup-remote-development.sh` | WSL remote dev orchestrator |
| Registry | `scripts/components/registry.sh` | YAML-backed component metadata |

## Machine-Readable Manifest
`components.yaml` enumerates configurable components with metadata (id, script, deps, tests).

## Libraries

| File | Purpose |
|------|---------|
| `lib/state-management.sh` | Track install state & component statuses |
| `lib/constants.sh` | Central default paths (state file, projects) |
| `lib/platform-detection.sh` | Platform & shell detection |
| `lib/log.sh` (planned) | Structured logging abstraction (levels) |

## Tests
Entry: `scripts/run-tests.sh`. New provisioning & idempotency tests located under `test/` (e.g., `test-setup-projects-idempotent.sh`). PowerShell tests auto-skip if `pwsh` missing.

## Key Environment Variables
See `env-schema.md` for the authoritative list.

## Architectural Decisions
ADRs under `docs/adr/` (ADR 0001 defines component manifest + headers).

## Common Automation Tasks

| Task | Command |
|------|---------|
| Lint scripts | `just lint` |
| Run tests | `just test` |
| Unified setup | `just setup` |
| Install deps | `just install-deps` |

## Idempotency Contract
All setup scripts should be re-runnable without destructive side effects. State tracked at `$HOME/.dotfiles-state` (override via `DOTFILES_STATE_FILE`).

## Extension Opportunities
- Expand per-component test matrix (Q8)
- Logging abstraction (`lib/log.sh`) adoption
- Multi-OS CI matrix
- Security scanning (Dependabot)

## Retrieval Tips (for Agents)
Search anchors: `components.yaml`, `setup-wizard.sh`, `install-oh-my-posh.sh`, `env-schema.md`, `AI_INDEX.md`.
