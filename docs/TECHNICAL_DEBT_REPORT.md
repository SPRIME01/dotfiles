# Technical Debt Report

Generated: 2025-08-13
Scope: dotfiles repository (cross-shell configuration, setup automation, testing harness, documentation)

## 1. Executive Summary
The project provides robust cross-shell setup but has fragmentation in setup scripts, legacy artifacts, and uneven automation. Technical debt concentrates in configuration sprawl, duplicated orchestration logic, lack of standardized linting/format enforcement, and partial test coverage for higher‑risk provisioning scripts. Addressing a focused backlog will improve maintainability, AI agent assist accuracy, and long-term sustainability.

Top 5 Priorities:
1. Consolidate setup wizards (remove duplication) – High impact / Medium effort
2. Introduce shell script linting & formatting (shfmt + shellcheck) – High impact / Low effort
3. Unify environment loading & remove legacy loader (`load_env_legacy.sh`) – Medium/high impact / Low effort
4. Add structured test coverage for remote dev, SSH bridge, projects setup – High impact / Medium effort
5. Create authoritative config & .env schema doc + ADR index – Medium impact / Low effort

## 2. Methodology
Assessed repository structure, scripts, documentation, and tests across six debt categories:
- Dependency
- Configuration
- Code Quality / Architecture
- AI Agent Compatibility
- Testing & QA
- Documentation
Each item scored (Impact: Low/Med/High, Effort: S/M/L) with qualitative rationale.

## 3. Debt Inventory by Category

### 3.1 Dependency Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| D1 | ~~Unpinned external tooling~~ | ~~Reliance on latest curl, jq, socat, oh-my-posh installs without version pinning~~ | ~~Med~~ | ~~S~~ | Added pinned installer + checksum + skip flag (oh-my-posh); pattern ready for other tools
| D2 | ~~Implicit openssh-server dependency via apt side-effects~~ | ~~`apt install socat` pulled/triggered openssh-server postinst failing (no systemd)~~ | ~~Med~~ | ~~M~~ | Added guarded installer `scripts/install-dependencies.sh` (skips server when no systemd)
| D3 | ~~Redundant multi-platform detection functions~~ | ~~Platform detection scattered (scripts + lib)~~ | ~~Low~~ | ~~S~~ | Added unified helpers in `lib/platform-detection.sh` (`is_linux`, `is_wsl`, etc.) and refactored `bootstrap.sh`
| D4 | ~~Potential unused backup scripts~~ | ~~Backups (e.g., multiple `.bak` PS profiles) kept in repo root/powerShell folder~~ | ~~Low~~ | ~~S~~ | Removed .bak files; added ignore pattern
| D5 | ~~No dependency security scan~~ | ~~No automated CVE audit (even minimal)~~ | ~~Med~~ | ~~S~~ | Added Dependabot config `.github/dependabot.yml`

### 3.2 Configuration Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| C1 | ~~Duplicated setup logic~~ | ~~`setup-wizard.sh` vs `setup-wizard-improved.sh` vs PS variant~~ | ~~High~~ | ~~M~~ | Consolidated into single `scripts/setup-wizard.sh` (improved version); removed duplicate script
| C2 | ~~Mixed naming conventions~~ | `setup-wsl2-remote-access.sh` vs `setup-remote-development.sh` | ~~Med~~ | ~~S~~ | Naming conventions doc `docs/naming.md` + CONTRIBUTING reference
| C3 | ~~Hardcoded paths & magic strings~~ | ~~Repeated `~/projects`, `.dotfiles-state` literals~~ | ~~Med~~ | ~~S~~ | Added `lib/constants.sh` and updated scripts
| C4 | ~~Environment variable schema undocumented~~ | ~~No single reference for expected .env keys~~ | ~~Med~~ | ~~S~~ | Added `docs/env-schema.md`
| C5 | ~~Insecure default permission warnings reactive not proactive~~ | ~~Loader warns after detection, no pre-flight audit~~ | ~~Low~~ | ~~M~~ | Added proactive `scripts/permission-audit.sh` (test pending for T7)
| C6 | ~~Lack of profile selection automation~~ | ~~manual profile selection; not centrally configurable~~ | ~~Low~~ | ~~M~~ | Implemented `scripts/select-profile.sh` + doctor integration
| C7 | ~~Partial Windows/WSL conditional scatter~~ | ~~WSL checks repeated across scripts~~ | ~~Med~~ | ~~S~~ | Provided helper predicates; beginning incremental refactors (bootstrap updated)

### 3.3 Code Quality / Architecture Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| Q1 | ~~Duplicate logic across wizards~~ | ~~State reading, component loops reimplemented~~ | ~~High~~ | ~~M~~ | Resolved via unified wizard script
| Q2 | ~~Legacy file still present~~ | ~~`load_env_legacy.sh` kept; risks confusion~~ | ~~Med~~ | ~~S~~ | Removed legacy script; unified on `scripts/load_env.sh`
| Q3 | ~~Ad-hoc error handling variance~~ | ~~Some scripts `set -euo pipefail`, others missing strict mode~~ | ~~Med~~ | ~~S~~ | Enforced strict mode + headers across key scripts (bootstrap, update, projects, installers)
| Q4 | ~~Inconsistent function naming~~ | ~~mix snake-case vs hyphen scripts~~ | ~~Med~~ | ~~S~~ | Naming conventions doc created; gradual refactors ongoing
| Q5 | ~~Imperative monolithic scripts~~ | ~~Some >300 lines (wizard) reduce composability~~ | ~~Med~~ | ~~M~~ | Modular bootstrap implemented (`lib/bootstrap/steps.sh`); further per-component tests tracked under Q8
| Q6 | ~~Minimal abstraction for component registry~~ | ~~Components defined inline (hard to extend)~~ | ~~Med~~ | ~~M~~ | Added `scripts/components/registry.sh` using `components.yaml`
| Q7 | ~~Lack of logging abstraction~~ | ~~echo used directly; no verbosity levels~~ | ~~Low~~ | ~~S~~ | Added `lib/log.sh` and integrated into key scripts
| Q8 | No idempotency contract tests for each component | Only high-level tests | Med | M | Progress: deterministic tests (bootstrap, projects, MCP helper), vscode, wizard regression, oh-my-posh; remaining: zsh plugins granular

### 3.4 AI Agent Compatibility Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| A1 | ~~Multiple overlapping docs (README, interface, audit reports)~~ | ~~Increases retrieval noise~~ | ~~High~~ | ~~M~~ | Added `docs/AI_INDEX.md`
| A2 | ~~No machine-readable component manifest~~ | ~~Hard for agent to plan modifications~~ | ~~High~~ | ~~M~~ | Added `components.yaml`
| A3 | ~~Lacking structured metadata in scripts~~ | ~~Few doc headers, no standardized block~~ | ~~Med~~ | ~~S~~ | Added standardized headers to key scripts (bootstrap, update, wizard, etc.)
| A4 | ~~Mixed naming patterns hinder semantic search~~ | ~~Harder vector retrieval~~ | ~~Med~~ | ~~S~~ | Naming conventions doc + gradual refactor
| A5 | ~~Missing task automation descriptors~~ | ~~No justfile comments for each target~~ | ~~Low~~ | ~~S~~ | Enhanced Justfile annotations
| A6 | ~~Scattered decision context~~ | ~~No ADR directory~~ | ~~Med~~ | ~~S~~ | Added `docs/adr/` with ADR 0001
| A7 | ~~No CI pipeline to anchor agent actions~~ | ~~Hard to validate in PR automatically~~ | ~~High~~ | ~~M~~ | Added `.github/workflows/ci.yml` (tests + lint)

### 3.5 Testing & QA Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| T1 | ~~Uneven coverage for provisioning scripts~~ | ~~`setup-projects-idempotent.sh`, remote dev not fully tested~~ | ~~High~~ | ~~M~~ | Added tests: `test/test-setup-projects-idempotent.sh`, `test/test-setup-remote-development-prompts.sh`
| T2 | ~~PowerShell test coverage limited~~ | ~~Only env loader validated~~ | ~~Med~~ | ~~M~~ | Added tests: aliases, theme fallback, oh-my-posh presence
| T3 | ~~No regression tests for wizards UI logic~~ | ~~Logic changes risk breakage~~ | ~~Med~~ | ~~M~~ | Added `test/test-wizard-regression.sh`
| T4 | ~~Absence of lint/static analysis gates~~ | ~~Shellcheck not enforced~~ | ~~High~~ | ~~S~~ | Implemented `tools/lint.sh` + Just targets (lint/format)
| T5 | No test matrix across OS versions | Single environment run | Low | L | Matrix added (Ubuntu + macOS) in CI workflow
| T6 | Lack of performance baseline (startup time) | Hard to detect regressions | Low | M | Added `tools/measure-startup.sh`
| T7 | No security-focused tests (permissions) | Permissions are reactive | Med | S | Added `test/test-permissions.sh` (auditor exercised)
| TH1 | (Harness) No skip classification | Skipped/conditional tests previously counted as failures | Low | S | Added skip-aware runner (PASS/SKIP/FAIL counters) improving signal quality

### 3.6 Documentation Debt
| ID | Issue | Detail | Impact | Effort | Notes |
|----|-------|--------|--------|--------|-------|
| Doc1 | ~~Redundant wizard descriptions~~ | ~~Maintained in multiple docs~~ | ~~Med~~ | ~~S~~ | Centralized `docs/wizard.md`
| Doc2 | ~~Fragmented troubleshooting steps~~ | ~~Spread across docs & README~~ | ~~Med~~ | ~~S~~ | Added `docs/troubleshooting.md`
| Doc3 | ~~No ADRs~~ | ~~Architectural decisions implicit~~ | ~~Med~~ | ~~S~~ | ADR system established
| Doc4 | ~~Lacks .env key catalog & examples~~ | ~~Hard for new users~~ | ~~Med~~ | ~~S~~ | Added env schema documentation
| Doc5 | ~~Missing contributor guidelines (style, commit, naming)~~ | ~~Inconsistent future changes~~ | ~~Med~~ | ~~S~~ | Added CONTRIBUTING.md
| Doc6 | ~~No maintenance schedule documented~~ | ~~Unclear update cadence~~ | ~~Low~~ | ~~S~~ | Added `docs/maintenance.md`
| Doc7 | ~~No quick fact sheet for AI agent context injection~~ | ~~Slows retrieval~~ | ~~Med~~ | ~~S~~ | Added `docs/AI_INDEX.md`

## 4. Prioritized Backlog (Consolidated)
| Priority | ID | Title | Category | Impact | Effort | Rationale |
|----------|----|-------|----------|--------|--------|-----------|
| P1 | C1/Q1 | ~~Consolidate setup wizards~~ | Config/Quality | High | M | Completed (single unified wizard)
| P1 | T4 | ~~Add shell lint & format (shellcheck/shfmt)~~ | Testing | High | S | Completed (lint tooling present)
| P1 | A7 | ~~Introduce CI workflow (tests + lint)~~ | AI/Testing | High | M | Completed (CI workflow present)
| P1 | Q2 | ~~Remove legacy env loader~~ | Quality | Med | S | Completed (legacy loader removed)
| P1 | D2 | ~~Avoid openssh-server dependency in minimal env~~ | Dependency | Med | M | Completed (guarded dependency installer)
| P2 | A2 | ~~Component manifest (JSON/YAML)~~ | AI | High | M | Completed (components.yaml)
| P2 | T1 | ~~Provisioning script tests~~ | Testing | High | M | Completed (new tests added)
| P2 | C4/Doc4 | ~~.env schema documentation~~ | Config/Doc | Med | S | Completed (env-schema.md)
| P2 | Doc5 | ~~Add CONTRIBUTING guidelines~~ | Doc | Med | S | Completed (CONTRIBUTING.md)
| P2 | A6/Doc3 | ~~ADR system introduction~~ | AI/Doc | Med | S | Completed (ADR 0001 + template)
| P3 | Q6 | Component registry abstraction | Quality | Med | M | Future extensibility
| P3 | T2 | ~~Expand PowerShell tests~~ | Testing | Med | M | Added aliases, theme, oh-my-posh tests
| P3 | D1 | ~~Version pin / checksum critical binaries~~ | Dependency | Med | S | Completed (pinned + checksum pattern)
| P3 | C3 | Central constants file | Config | Med | S | Pending (not yet implemented)
| P3 | A3 | ~~Script header doc blocks~~ | AI | Med | S | Implemented in key scripts
| P3 | Doc2 | ~~Unified troubleshooting hub~~ | Doc | Med | S | Added troubleshooting doc
| P4 | T6 | ~~Startup performance baseline~~ | Testing | Low | M | measure-startup script added
| P4 | T5 | ~~Multi-OS matrix CI~~ | Testing | Low | L | Matrix workflow added
| P4 | D5 | ~~Automated dependency security scan~~ | Dependency | Med | S | Dependabot config added
| P4 | Q7 | ~~Logging abstraction~~ | Quality | Low | S | Added lib/log.sh and integrated
| P4 | Q8 | Per-component idempotency tests | Quality | Med | M | Risk reduction
| P4 | A5 | Justfile target annotations | AI | Low | S | Improves discoverability

## 5. Remediation Roadmap
### Phase 0 (Day 0–2 Quick Wins)
~~- Remove `load_env_legacy.sh` (Q2)~~
~~- Add shellcheck + shfmt tooling & Just targets (T4)~~
- Create CONTRIBUTING.md (Doc5)
- Add .env schema doc (C4/Doc4)
- Introduce script header template (A3)

### Phase 1 (Week 1)
~~- Consolidate setup wizards into unified script with modes (C1/Q1)~~
- Add CI workflow: lint + tests (A7)
- Add component manifest file `components.yaml` (A2)
~~- Adjust socat/openSSH dependency logic, detect systemd (D2)~~

### Phase 2 (Weeks 2–3)
- Provisioning & remote dev tests (T1)
- PowerShell extended tests (T2)
- Central constants file & de-dup WSL checks (C3/C7)
- Introduce ADR directory (A6/Doc3)

### Phase 3 (Month 2)
- Component registry abstraction (Q6)
- Idempotency per-component tests (Q8)
- Version pinning / checksum (D1)
- Unified troubleshooting hub (Doc2)

### Phase 4 (Month 3+)
- Multi-OS CI matrix (T5)
- Startup performance benchmarks (T6)
- Logging abstraction (Q7)
- Dependency security scan automation (D5)

## 6. AI Agent Enablement Enhancements
| Enhancement | Benefit |
|-------------|---------|
| `components.yaml` manifest | Enables structured planning & automated edits
| Script header doc blocks | Improves retrieval precision for AI
| ADR index | Context grounding for architectural choices
| AI index file (`AI_INDEX.md`) | Rapid context injection for agent sessions
| Justfile annotations | Self-describing automation tasks
| CI pipeline results badge | Feedback loop for agent correctness

## 7. Risk Assessment
| Risk | Current Exposure | Mitigation |
|------|------------------|-----------|
| Wizard divergence | High (two code paths) | Mitigated (single code path) |
| Silent config drift | Medium | Lint + CI gates |
| Install failure in non-systemd env | Medium | Guard openssh-server (D2) |
| Future contributor inconsistency | Medium | CONTRIBUTING + ADRs |
| AI misunderstanding of state | High | Component manifest + headers |

## 8. Metrics & Success Criteria
| Goal | Metric | Target |
|------|--------|--------|
| Reduce duplicate setup logic | Lines removed vs added | Achieved via removal of duplicate script |
| Improve script quality | Shellcheck warnings | 0 blocking, <5 total info |
| Enhance test coverage | New scripts covered | +5 critical scripts |
| Strengthen AI compatibility | Retrieval precision (manual sample) | 90% relevant hits |
| Stability in provisioning | Re-runs without failure | 100% in test matrix |

## 9. Implementation Guidelines
- Introduce `tools/lint.sh` running shellcheck & shfmt (fail on error)
- Add `.shell_header_template` comment block for new scripts
- Use semantic commit messages (docs:, chore:, feat:, test:, refactor:)
- Add ADR template: Title, Context, Decision, Consequences

## 10. Appendix
### A. Proposed Script Header Template
```bash
#!/usr/bin/env bash
# Description: <one line>
# Category: <setup|diagnostic|utility>
# Dependencies: <jq,curl,...>
# Idempotent: yes/no (explain)
# Inputs: <env vars or args>
# Outputs: <files, state vars>
# Exit Codes: 0 success, >0 specific failures
# Maintainer: <name>
set -euo pipefail
```

### B. Component Manifest Skeleton
```yaml
components:
  - id: zsh_config
    description: Install and configure Zsh + Oh My Zsh + p10k
    script: scripts/components/zsh.sh
    depends_on: [common_env]
    idempotent: true
    tests: [test/test-zsh-startup.sh]
  - id: vscode_settings
    description: Merge VS Code settings
    script: install/vscode.sh
    idempotent: true
    tests: [test/test-vscode-integration.sh]
```

### C. ADR Template
```md
# ADR <number>: <Title>
Date: YYYY-MM-DD
Status: Proposed | Accepted | Superseded | Deprecated
## Context
## Decision
## Consequences
## Alternatives Considered
```

---
Prepared for: Project Maintainers
Author: Automated Technical Debt Analysis Agent
