# Documentation Knowledge System

Welcome to the comprehensive technical documentation for the `dotfiles` repository. This knowledge system is structured using the **Diátaxis framework** combined with **progressive disclosure**, serving both newcomers seeking a conceptual on-ramp and experienced engineers needing exact implementation details and invariants.

---

## 🗺️ Master Documentation Anchors

- **[System Orientation (Layer 0)](index.md):** Plain-language definition, 1-picture architecture, core concepts, and intent-based navigation.
- **[System Mental Model (Layer 1)](mental-model.md):** The developer cockpit metaphor, host boundaries, abstractions, and state ownership.
- **[Architecture Specification (Layer 2)](architecture.md):** Canonical architectural master document covering logical, runtime, dependency, data, control flow, and security views.
- **[Documentation Map](documentation-map.md):** Exhaustive catalog of every page, purpose, audience need, and Diátaxis classification.
- **[Source Map](source-map.md):** Symbol-level traceability index connecting architectural concepts directly to implementation code and tests.

---

## 📚 Diátaxis Documentation Quadrants

### 1. 🎓 Tutorials (Learning-Oriented)
Step-by-step guided lessons from a known initial state to a verified outcome:
- [New Machine Setup](tutorials/new-machine-setup.md) — First-time bootstrap on Linux or WSL2.
- [Windows & WSL2 Integration](tutorials/windows-wsl-integration.md) — Bridging Windows PowerShell 7 to WSL2 over UNC.
- [Tailscale SSH Remote Access](tutorials/tailscale-ssh-setup.md) — Secure, keyless SSH access into WSL2.
- [Updating an Existing Machine](tutorials/update-existing-machine.md) — Pulling updates and applying templates.

### 2. 🛠️ How-To Guides (Goal-Oriented)
Practical recipes to solve real operational problems:
- [Add an Alias or Function Across Shells](how-to/add-alias-or-function.md) — Cross-platform command authoring and proxy regeneration.
- [Diagnose and Repair Shell Startup](how-to/diagnose-and-repair.md) — Benchmarking with `measure-startup.sh` and `doctor.sh`.
- [Manage Encrypted Secrets with SOPS](how-to/manage-secrets-sops.md) — Editing `.secrets.json` with Age encryption.
- [Configure Model Context Protocol (MCP)](how-to/configure-mcp.md) — Setting up AI assistant context bridges.
- [Chezmoi on Windows and WSL](how-to/chezmoi-windows.md) — Safe preview and template application.
- [Comprehensive Troubleshooting Matrix](how-to/troubleshooting.md) — Symptom-to-solution triage for all failure modes.

### 3. 🧩 Subsystems & Explanations (Understanding-Oriented)
Deep architectural decomposition and design rationale:
- **Subsystem Guides:**
  - [Shell Loader Engine](subsystems/shell-loader.md)
  - [PowerShell Host Bridge](subsystems/powershell-host-bridge.md)
  - [Dotfile State & Templating](subsystems/dotfile-management.md)
  - [Environment Pipeline](subsystems/environment-pipeline.md)
  - [Secrets & Security](subsystems/secrets-security.md)
  - [AI & MCP Integration](subsystems/ai-mcp-integration.md)
  - [Automation & Verification](subsystems/automation-verification.md)
- **Workflows & Execution Traces:**
  - [POSIX Shell Startup](workflows/shell-startup.md)
  - [Windows PowerShell UNC Startup](workflows/powershell-unc-startup.md)
  - [Environment Sync & Systemd](workflows/env-sync.md)
  - [Secret Decryption & Editing](workflows/secrets-lifecycle.md)
  - [Machine Provisioning](workflows/provisioning.md)
  - [Automated Testing & Health Checks](workflows/testing-diagnostics.md)
- **Design Rationale:**
  - [Architectural Decisions & Trade-offs](explanation/design-decisions.md)

### 4. 📖 Technical Reference (Information-Oriented)
Authoritative, structured specifications:
- [CLI Commands Reference](reference/cli-commands.md) — Complete catalogue of all `just` tasks, `envctl.sh`, and `doctor.sh`.
- [Environment Variables Dictionary](reference/env-vars.md) — Detailed reference for all exported variables and flags.
- [Environment Schema](reference/env-schema.md) — Specifications for `.env` keys and formats.
- [PowerShell Architecture Reference](reference/ARCHITECTURE.md) — Historical and deep technical specification for PowerShell.
