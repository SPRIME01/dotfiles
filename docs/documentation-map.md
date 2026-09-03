# Documentation Map & Information Architecture

> **Purpose:** Comprehensive inventory and reading guide for every document in this repository, structured according to user intent, Diátaxis classification, and progressive depth.  

---

## 1. Global Navigation by Reader Intent

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Where Should I Start?                           │
├────────────────────────┬────────────────────────┬──────────────────────┤
│ "I am completely new"  │ "I need to fix/build"  │ "I want architecture"│
│ docs/index.md          │ docs/how-to/           │ docs/architecture.md │
│ docs/mental-model.md   │ docs/tutorials/        │ docs/subsystems/     │
├────────────────────────┼────────────────────────┼──────────────────────┤
│ "I need syntax/params" │ "Why is it built this?"│ "Find source code"   │
│ docs/reference/        │ docs/explanation/      │ docs/source-map.md   │
└────────────────────────┴────────────────────────┴──────────────────────┘
```

---

## 2. Complete Page Inventory & Classification

| Document Path | Diátaxis Type | Primary Audience Need | Purpose | Prerequisites | Related Pages |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`docs/index.md`** | **Orientation** | High-level overview & quickstart | Establish system identity, 1-picture architecture, core concepts, and intent navigation. | None | `mental-model.md`, `architecture.md` |
| **`docs/mental-model.md`** | **Orientation / Concept** | Understand conceptual structure | Explain the cockpit mental model, host boundaries, abstractions, and state ownership. | `index.md` | `architecture.md`, `subsystems/` |
| **`docs/architecture.md`** | **Architecture** | System engineers & auditors | Authoritative canonical architecture covering logical, runtime, dependency, and security views. | `mental-model.md` | `documentation-map.md`, `source-map.md` |
| **`docs/documentation-map.md`** | **Navigation Meta** | Navigating documentation | Full inventory of all docs, Diátaxis types, prerequisites, and cross-links. | None | `index.md`, `source-map.md` |
| **`docs/source-map.md`** | **Traceability Meta** | Locating concrete implementation | Connects every concept and capability directly to files, symbols, functions, and tests. | `architecture.md` | All subsystem guides |
| **`docs/subsystems/shell-loader.md`** | **Explanation / Ref** | Shell configuration engineering | Detailed breakdown of `.shell_init.sh`, `shell/loader.sh`, and POSIX startup. | `mental-model.md` | `workflows/shell-startup.md` |
| **`docs/subsystems/powershell-host-bridge.md`** | **Explanation / Ref** | Windows/WSL integration engineering | Deep dive into Windows bootstrap, UNC 9P bridge, and `Aliases.psm1` lazy proxies. | `architecture.md` | `workflows/powershell-unc-startup.md` |
| **`docs/subsystems/dotfile-management.md`** | **Explanation / Ref** | Dotfile & template maintenance | Mechanics of `chezmoi`, deny-by-default `.chezmoiignore`, and `~/.dotfiles-state`. | `index.md` | `workflows/provisioning.md` |
| **`docs/subsystems/environment-pipeline.md`** | **Explanation / Ref** | Environment & secret lifecycle | How `.env` is safely parsed, deduplicated, and synchronized to systemd and direnv. | `mental-model.md` | `workflows/env-sync.md` |
| **`docs/subsystems/secrets-security.md`** | **Explanation / Ref** | Security audit & secret handling | Architecture of SOPS, Age asymmetric encryption, and checksum verification. | `architecture.md` | `workflows/secrets-lifecycle.md` |
| **`docs/subsystems/ai-mcp-integration.md`** | **Explanation / Ref** | AI assistant integration | Model Context Protocol gateway setup, VS Code integration, and bridge wrappers. | `index.md` | `how-to/configure-mcp.md` |
| **`docs/subsystems/automation-verification.md`** | **Explanation / Ref** | Testing & diagnostics | Architecture of `justfile`, `scripts/doctor.sh`, and the isolated test framework. | `architecture.md` | `workflows/testing-diagnostics.md` |
| **`docs/workflows/shell-startup.md`** | **Execution Trace** | Debugging POSIX startup | Step-by-step trace and sequence diagram of interactive Zsh/Bash startup. | `subsystems/shell-loader.md` | `how-to/diagnose-and-repair.md` |
| **`docs/workflows/powershell-unc-startup.md`** | **Execution Trace** | Debugging Windows startup | Step-by-step trace of Windows PowerShell crossing hypervisor over UNC to WSL. | `subsystems/powershell-host-bridge.md` | `tutorials/windows-wsl-integration.md` |
| **`docs/workflows/env-sync.md`** | **Execution Trace** | Tracing environment propagation | Trace from `just env-add` to `.env`, `direnv`, and `systemd --user`. | `subsystems/environment-pipeline.md` | `how-to/manage-secrets-sops.md` |
| **`docs/workflows/secrets-lifecycle.md`** | **Execution Trace** | Tracing secret encryption | Trace of `just secrets-edit` decryption, buffer modification, and Age re-encryption. | `subsystems/secrets-security.md` | `how-to/SECRET_MANAGEMENT.md` |
| **`docs/workflows/provisioning.md`** | **Execution Trace** | Machine bootstrap trace | End-to-end execution path from `git clone` to `install.sh`, `bootstrap.sh`, and `setup-pwsh7`. | `subsystems/dotfile-management.md` | `tutorials/new-machine-setup.md` |
| **`docs/workflows/testing-diagnostics.md`** | **Execution Trace** | Verification pipeline trace | How `test/run-all-tests.sh` executes test suites in clean subshells (`env -i`). | `subsystems/automation-verification.md` | `reference/cli-commands.md` |
| **`docs/explanation/design-decisions.md`** | **Explanation** | Understand design rationale & trade-offs | Detailed justifications for UNC paths, lazy proxies, deny-by-default, and confirmed vs inferred rationale. | `architecture.md` | `subsystems/` |
| **`docs/tutorials/new-machine-setup.md`** | **Tutorial** | Guided first-time setup on Linux/WSL | Hands-on walkthrough to clone, install, and verify the environment. | None | `tutorials/windows-wsl-integration.md` |
| **`docs/tutorials/windows-wsl-integration.md`** | **Tutorial** | Guided Windows PowerShell integration | Hands-on walkthrough to set up Windows PowerShell 7 and bridge it to WSL2. | `tutorials/new-machine-setup.md` | `subsystems/powershell-host-bridge.md` |
| **`docs/how-to/add-alias-or-function.md`** | **How-To Guide** | Add a command across all shells | Step-by-step instructions to add aliases in Bash, Zsh, and PowerShell with proxy regeneration. | None | `reference/commands.md` |
| **`docs/how-to/diagnose-and-repair.md`** | **How-To Guide** | Fix slow startup or broken state | Step-by-step guide to run `doctor.sh`, profile startup with `DOTFILES_PROFILE=1`, and fix issues. | None | `workflows/testing-diagnostics.md` |
| **`docs/how-to/troubleshooting.md`** | **How-To / Reference** | Resolve common failures | Comprehensive failure mode matrix mapping symptoms, causes, recovery steps, and source trails. | None | All subsystem guides |
| **`docs/reference/cli-commands.md`** | **Reference** | Look up tasks and CLI commands | Exhaustive listing of all `just` recipes, `envctl.sh`, `doctor.sh`, and helper scripts. | None | `justfile` |
| **`docs/reference/env-vars.md`** | **Reference** | Look up environment variables | Complete dictionary of all exported `DOTFILES_*`, `PROJECTS_*`, and tool variables. | None | `subsystems/environment-pipeline.md` |
