# Source Map & Traceability Index

> **Purpose:** Authoritative mapping of architectural concepts, capabilities, and invariants to concrete source files, symbols, functions, configurations, and verification tests.  
> **Traceability Level:** Symbol and line-level verification.  

---

## 1. Capability to Implementation Map

| Capability | Core Implementation Files | Key Symbols & Functions | Verification Tests |
| :--- | :--- | :--- | :--- |
| **POSIX Shell Initialization** | `.shell_init.sh`<br>`shell/loader.sh`<br>`.zshrc` | `DOTFILES_ROOT`<br>`safe_source`<br>`__load_wsl_integration`<br>`__load_platform_config` | `test/test-environment-loading.sh`<br>`test/test-no-deprecated-loaders.sh` |
| **Windows PowerShell Profile Bridge** | `scripts/setup-pwsh7.sh`<br>`PowerShell/Microsoft.PowerShell_profile.ps1` | `DOTFILES_WINDOWS_BOOTSTRAP_LOADING`<br>`DOTFILES_PWSH_PROFILE_LOADING`<br>`\\wsl.localhost\Ubuntu\...` | `test/test-powershell-aliases.ps1`<br>`test/test-powershell-theme.ps1` |
| **PowerShell Lazy-Loading Proxies** | `PowerShell/Microsoft.PowerShell_profile.ps1`<br>`PowerShell/Modules/Aliases/Aliases.psm1`<br>`PowerShell/Modules/Aliases/Update-AliasesModule.ps1` | `function gs { ... }`<br>`function finddir { ... }`<br>`Get-GitStatus`<br>`Find-Directory` | `test/test-powershell-aliases.ps1` |
| **Platform & OS Detection** | `lib/platform-detection.sh` | `detect_platform`<br>`is_linux`<br>`is_macos`<br>`is_wsl`<br>`is_windows`<br>`is_unix` | `test/test-environment.sh` |
| **Safe Environment Loading** | `lib/env-loader.sh`<br>`PowerShell/Utils/Load-Env.ps1` | `load_env_file_secure`<br>`add_path_once`<br>`load_tool_modules` | `test/test-environment.sh`<br>`test/test-no-deprecated-loaders.sh` |
| **Environment Variable CRUD** | `scripts/envctl.sh` | `ensure_file`<br>`add`<br>`remove`<br>`get`<br>`list` | `test/test-permissions.sh` |
| **Systemd Desktop Sync** | `scripts/sync-env-to-systemd.sh`<br>`scripts/export-to-systemd-env.sh` | `systemctl --user set-environment` | Interactive validation with VS Code |
| **Declarative Dotfile Templating** | `.chezmoiignore`<br>`dot_bashrc.tmpl`<br>`dot_zshrc.tmpl`<br>`dot_mise.toml`<br>`dot_justfile` | Whitelist pattern (`*`, `!.bashrc`, etc.)<br>`__dotfiles_try_source_common` | `test/test-chezmoi-templates.sh` |
| **Idempotent Installation State** | `lib/state-management.sh`<br>`components.yaml` | `init_state_file`<br>`write_state_key`<br>`read_state_key`<br>`has_state_key` | `test/test-bootstrap-idempotent.sh` |
| **Cryptographic Secure Installer** | `lib/secure-install.sh`<br>`lib/constants.sh` | `secure_install`<br>`OMP_INSTALLER_URL`<br>`OMP_INSTALLER_SHA256` | `test/test-oh-my-posh-checksum.sh`<br>`test/test-oh-my-posh-skip.sh` |
| **Secret Encryption (SOPS + Age)** | `.sops.yaml`<br>`.secrets.json`<br>`justfile` | `creation_rules`<br>`sops .secrets.json`<br>`just secrets-edit` | Manual verification via Age private key |
| **Model Context Protocol (MCP)** | `mcp/servers.json`<br>`mcp/mcp-helper.sh`<br>`mcp/mcp-helper.ps1`<br>`mcp/mcp-bridge-wrapper.sh` | `mcpServers`<br>`MCP_GATEWAY_URL`<br>`migrate-vscode-settings` | `test/test-mcp-idempotent.sh` |
| **VS Code Desktop Settings Integration** | `install/vscode.sh`<br>`mcp/migrate-vscode-settings.sh` | JSON configuration merge logic | `test/test-vscode-integration.sh` |
| **Remote Access via Tailscale SSH** | `scripts/setup-wsl2-remote-access.sh` | `setup_tailscale_ssh`<br>`update_ssh_config` | `test/test-wsl2-remote-access.sh` |
| **Universal Task Automation** | `justfile`<br>`dot_justfile` | `test`, `lint`, `format`, `doctor`, `setup-pwsh7` | `test/test-global-justfile.sh` |
| **Diagnostics & Health Audits** | `scripts/doctor.sh`<br>`tools/lint.sh`<br>`tools/measure-startup.sh` | `QUICK`, `VERBOSE`, `STRICT`<br>`shellcheck`, `shfmt` | `test/test-doctor.sh`<br>`test/test-doctor-flags.sh` |
| **Unified Test Framework** | `test/framework.sh`<br>`test/run-all-tests.sh` | `test_assert`<br>`test_assert_contains`<br>`test_summary` | `test/run-all-tests.sh` |

---

## 2. Invariant & Contract Evidence

| Invariant / Contract | Enforced In | Concrete Implementation Mechanism |
| :--- | :--- | :--- |
| **Insecure permissions on `.env` prohibited** | `scripts/envctl.sh`<br>`scripts/fix-env-perms.sh` | `umask 077`; `chmod 600 "$ENV_FILE"`. Tested by `test/test-permissions.sh`. |
| **Deny-by-default home deployment** | `.chezmoiignore` | Line 1: `*`. Only explicitly un-ignored paths (`!.bashrc`, etc.) are rendered. |
| **Terminal-Icons never inside WSL pwsh** | `scripts/setup-pwsh7.sh` | Wrapped in `$IsWindows -and $PSVersionTable.PSEdition -eq 'Core'` inside the Windows bootstrap profile template. |
| **No deprecated `load_env.sh`** | `test/test-no-deprecated-loaders.sh` | Greps all shell configs for `scripts/load_env.sh` and fails if any reference is detected. |
| **Deterministic `DOTFILES_ROOT`** | `.shell_init.sh`<br>`shell/loader.sh` | Uses script source inspection (`${BASH_SOURCE[0]}` or zsh `${(%):-%x}`) instead of `$PWD`. |
| **Deduplicated `$PATH` additions** | `lib/env-loader.sh` | `add_path_once` strips existing instances of directory before prepending. |
| **Atomic state updates** | `lib/state-management.sh` | Uses `awk` + `mktemp` swap to rewrite `$DOTFILES_STATE_FILE` without truncation races. |
