# Technical Reference: CLI Commands & Task Automation

> **Type:** Diátaxis Reference (Authoritative specifications, concise, structured)  
> **Primary Command Facade:** `just` (`justfile`), `scripts/envctl.sh`, `scripts/doctor.sh`, `mcp/mcp-helper.sh`  

---

## 1. Top-Level `just` Command Catalog

The repository uses `just` as its task facade. Run `just` (or `just default`) to list all tasks.

### Core Lifecycle & Setup

| Recipe | Description | Implementation Path |
| :--- | :--- | :--- |
| `just setup` | Launch the interactive setup wizard for Unix shells | `scripts/setup-wizard.sh` |
| `just setup-dry-run` | Run the setup wizard without making persistent filesystem modifications | `scripts/setup-wizard.sh --dry-run` |
| `just setup-windows` | Launch the interactive setup wizard for Windows PowerShell | `scripts/setup-wizard.ps1` |
| `just install` | Run non-interactive full installation | `install_complete.sh` |
| `just install-dry-run` | Test full installation in dry-run mode | `install_complete.sh --dry-run` |
| `just update` | Pull latest commits and apply chezmoi templates | `update.sh` |
| `just setup-projects` | Create projects directory and setup cross-host symlink | `scripts/setup-projects-idempotent.sh` |
| `just setup-pwsh7` | Generate Windows PowerShell 7 profile bridging to WSL via UNC | `scripts/setup-pwsh7.sh` |
| `just setup-pwsh7-dry-run`| Preview Windows PowerShell 7 profile generation without writing | `scripts/setup-pwsh7.sh --dry-run` |

### Environment & Secret Management

| Recipe | Description | Arguments / Usage | Implementation Path |
| :--- | :--- | :--- | :--- |
| `just env-add` | Add or update key-value pair in `.env` | `just env-add KEY=VAL` | `scripts/envctl.sh add` |
| `just env-remove` | Remove key from `.env` | `just env-remove KEY` | `scripts/envctl.sh remove` |
| `just env-list` | Display all keys in `.env` | `just env-list` | `scripts/envctl.sh list` |
| `just env-fix-perms` | Enforce strict `0600` permissions on `.env` | None | `scripts/fix-env-perms.sh` |
| `just sync-env` | Export `.env` variables to `systemd --user` for GUI apps | None | `scripts/sync-env-to-systemd.sh` |
| `just secrets-edit` | Decrypt and open `.secrets.json` in `$EDITOR` | None | `sops .secrets.json` |
| `just secrets-view` | Print decrypted secrets to standard output | None | `sops -d .secrets.json` |
| `just secrets-encrypt`| Encrypt `.env` into `.env.encrypted` | None | `sops -e .env` |
| `just secrets-decrypt`| Decrypt `.env.encrypted` into `.env` | None | `sops -d .env.encrypted` |

### Verification, Quality & Diagnostics

| Recipe | Description | Implementation Path |
| :--- | :--- | :--- |
| `just test` | Run complete automated test suite across shells | `scripts/run-tests.sh` -> `test/run-all-tests.sh` |
| `just doctor` | Run basic system health and dependency check | `scripts/doctor.sh` |
| `just doctor-verbose` | Run health check with verbose diagnostic tracing | `scripts/doctor.sh --verbose` |
| `just doctor-strict` | Run health check and exit non-zero on any warning | `scripts/doctor.sh --strict` |
| `just lint` | Run shellcheck and check formatting with shfmt | `tools/lint.sh` |
| `just format` | Automatically format all shell scripts in-place | `shfmt -w .` |

---

## 2. Environment Controller: `scripts/envctl.sh`

### Syntax
```bash
bash scripts/envctl.sh [--file PATH] <command> [args...]
```

### Commands

| Command | Arguments | Description |
| :--- | :--- | :--- |
| `add` | `KEY VALUE` or `KEY=VALUE` | Adds key or updates existing key; enforces `0600` permissions |
| `remove` | `KEY` | Removes key and preserves surrounding comments |
| `get` | `KEY` | Outputs the current value of the key, or returns 1 if unset |
| `list` | None | Prints all non-comment `KEY=VALUE` pairs |

---

## 3. Diagnostic Doctor: `scripts/doctor.sh`

### Syntax
```bash
bash scripts/doctor.sh [--quick] [--verbose] [--strict]
```

### Options

| Flag | Description |
| :--- | :--- |
| `--quick` | Skips deep filesystem checks and checks only core environment variables |
| `--verbose` | Outputs full directory paths, computed platform names, and active shells |
| `--strict` | Fails with non-zero exit code if optional tools (e.g. `direnv`, `mise`) are missing or permissions loose |
