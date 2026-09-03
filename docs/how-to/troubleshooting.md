# Troubleshooting Guide & Failure Modes Matrix

> **Type:** Diátaxis How-To Guide / Diagnostic Reference  
> **Purpose:** Authoritative symptom-to-solution matrix mapping observable failures to root causes, diagnostic evidence, recovery procedures, and concrete source locations.  

---

## 1. Quick Triage Order

When experiencing unexpected behavior, run diagnostics in this exact sequence:

1. **System Health Audit:**
   ```bash
   bash scripts/doctor.sh --verbose
   ```
2. **Permission Audit:**
   ```bash
   bash scripts/permission-audit.sh
   ```
3. **Automated Test Matrix:**
   ```bash
   bash test/run-all-tests.sh
   ```

---

## 2. Comprehensive Failure Modes Matrix

### A. Shell Startup & Loader Subsystem

| Observable Symptom | Likely Cause | Subsystem | Diagnostic Evidence | Recovery Path | Source Locations |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Command 'zsh' not found` | Zsh binary not installed on Linux host | Shell Loader | `which zsh` returns non-zero | Run `sudo apt update && sudo apt install -y zsh` or `bash install_zsh.sh` | [install.sh](../../install.sh) |
| Startup takes > 1.5 seconds | Duplicate compinit or blocking network calls | Shell Loader | `DOTFILES_PROFILE=1 zsh` shows slow function | Inspect zprof output; ensure `skip_global_compinit=1` in `.zshrc` | [.shell_init.sh](../../.shell_init.sh), [tools/measure-startup.sh](../../tools/measure-startup.sh) |
| `DOTFILES_ROOT: unbound variable` | Subshell running with strict `set -u` before root derived | Shell Loader | Error output in subshell startup | Ensure `.shell_init.sh` derives `DOTFILES_ROOT` before strict mode | [.shell_init.sh](../../.shell_init.sh#L1-L30) |
| `p10k instant prompt: console output` warning | Commands printed stdout before instant prompt initialized | Shell Loader | Warning banner on terminal open | Move any echoing scripts below instant prompt block or set `POWERLEVEL9K_INSTANT_PROMPT=quiet` | [.shell_init.sh](../../.shell_init.sh) |

---

### B. Cross-Host Bridge & Windows PowerShell

| Observable Symptom | Likely Cause | Subsystem | Diagnostic Evidence | Recovery Path | Source Locations |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Cannot find path '\\wsl.localhost\...'` | WSL2 instance stopped or distribution renamed | Host Bridge | `Test-Path \\wsl.localhost\Ubuntu` is False | In Windows terminal, run `wsl -l -v` to check distro; run `just setup-pwsh7` from WSL | [scripts/setup-pwsh7.sh](../../scripts/setup-pwsh7.sh#L30-L70) |
| `Import-Clixml: Name attribute for dictionary key is incorrectly specified` | `Terminal-Icons` loaded inside Linux/WSL `pwsh` | Host Bridge | Error in WSL PowerShell pointing to `InstalledLocation` | Enforce `$IsWindows -and $PSVersionTable.PSEdition -eq 'Core'` guard in bootstrap profile | [PowerShell/Microsoft.PowerShell_profile.ps1](../../PowerShell/Microsoft.PowerShell_profile.ps1), [docs/reference/ARCHITECTURE.md](../reference/ARCHITECTURE.md#L235-L255) |
| Sluggish PowerShell startup (~1200ms) | `Aliases.psm1` imported greedily instead of via proxy | Host Bridge | `Measure-Command { . $PROFILE }` > 1000ms | Ensure `Aliases.psm1` is not imported at top level; use lazy-load proxies | [PowerShell/Microsoft.PowerShell_profile.ps1](../../PowerShell/Microsoft.PowerShell_profile.ps1#L120-L150) |
| OneDrive module path conflicts | PowerShell importing cloud-synced module copies | Host Bridge | `$env:PSModulePath` contains OneDrive paths | Re-run `just setup-pwsh7` to regenerate profile with OneDrive regex scrubbing | [scripts/setup-pwsh7.sh](../../scripts/setup-pwsh7.sh) |

---

### C. Environment, Security & Secrets

| Observable Symptom | Likely Cause | Subsystem | Diagnostic Evidence | Recovery Path | Source Locations |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `Insecure permissions detected: .env` | `.env` created with loose permissions (`0644`) | Environment Pipeline | `scripts/permission-audit.sh` flags file | Run `just env-fix-perms` or `chmod 600 .env` | [scripts/envctl.sh](../../scripts/envctl.sh), [scripts/fix-env-perms.sh](../../scripts/fix-env-perms.sh) |
| VS Code / GUI apps missing environment variables | Variables not exported to systemd user space | Environment Pipeline | Terminal has key, but GUI app does not | Run `just sync-env` and reload VS Code window (`Ctrl+Shift+P` -> `Reload Window`) | [scripts/sync-env-to-systemd.sh](../../scripts/sync-env-to-systemd.sh) |
| `direnv: error .envrc is blocked` | `.envrc` modified without approval | Environment Pipeline | `direnv status` shows blocked | Run `direnv allow` in the repository root | [.envrc](../../.envrc) |
| `SOPS: error opening file: age: no identity found` | Missing Age private key on local host | Secrets Security | `~/.config/sops/key.txt` does not exist | Restore Age private key to `~/.config/sops/key.txt` and set `chmod 600` | [.sops.yaml](../../.sops.yaml), [docs/how-to/SECRET_MANAGEMENT.md](SECRET_MANAGEMENT.md) |
| `Checksum verification failed!` during install | Upstream remote installer modified | Security Packaging | `lib/secure-install.sh` exits code 2 | Update checksum in `lib/constants.sh` via `bash lib/secure-install.sh fetch_checksum` | [lib/secure-install.sh](../../lib/secure-install.sh), [lib/constants.sh](../../lib/constants.sh) |

---

### D. Dotfiles & Chezmoi Templating

| Observable Symptom | Likely Cause | Subsystem | Diagnostic Evidence | Recovery Path | Source Locations |
| :--- | :--- | :--- | :--- | :--- | :--- |
| File edited in repo does not appear in `$HOME` | File omitted from `.chezmoiignore` whitelist | Dotfile State | `chezmoi diff` produces empty output | Add `!<filename>` to `.chezmoiignore`; run `chezmoi apply` | [.chezmoiignore](../../.chezmoiignore) |
| `chezmoi: syntax error in template` | Unterminated Go template expression | Dotfile State | Parse error during `chezmoi apply` | Test template locally: `chezmoi execute-template < dot_*.tmpl` | [dot_bashrc.tmpl](../../dot_bashrc.tmpl), [dot_bashrc.tmpl](../../dot_bashrc.tmpl) |
| State probe reports inconsistent setup | Setup interrupted before completion | Dotfile State | `read_state_key setup_completed` empty | Re-run `bash bootstrap.sh` (completely idempotent) | [lib/state-management.sh](../../lib/state-management.sh) |

---

## 3. Recovery Scripts Reference

The repository provides automated recovery recipes in `justfile`:

- `just repair-zshrc` — Re-links and re-applies `.zshrc` configuration cleanly.
- `just repair-bashrc` — Re-links and re-applies `.bashrc` configuration cleanly.
- `just env-fix-perms` — Hardens `.env` and `.dotfiles-state` permissions to `0600`.
- `just sync-env` — Refreshes `systemd --user` environment block for graphical apps.
- `just setup-pwsh7` — Rebuilds and writes the Windows PowerShell 7 UNC profile.
