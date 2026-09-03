# Technical Reference: Environment Variables Dictionary

> **Type:** Diátaxis Reference (Authoritative specifications, concise, structured)  
> **Scope:** Variables read or exported across POSIX shells and PowerShell 7  

---

## 1. Core System & Path Variables

| Variable Name | Type / Format | Set In | Purpose & Scope | Default Value |
| :--- | :--- | :--- | :--- | :--- |
| **`DOTFILES_ROOT`** | Absolute Path | `.shell_init.sh`<br>`loader.ps1` | Canonical root directory of the dotfiles repository. | Linux: `~/dotfiles`<br>Windows: `\\wsl.localhost\Ubuntu\...` |
| **`PROJECTS_ROOT`** | Absolute Path | `.shell_common.sh`<br>`.shell_init.sh` | Root directory for developer project checkouts. Used by `projects` and `cddot`. | Linux: `~/projects`<br>Windows: `$env:USERPROFILE\projects` |
| **`DOTFILES_PLATFORM`**| String Enum | `lib/platform-detection.sh` | Runtime OS platform identifier (`linux`, `macos`, `wsl`, `windows`). | Detected via `uname -s` / `/proc/version` |
| **`DOTFILES_SHELL`** | String Enum | `lib/platform-detection.sh` | Active shell binary name (`bash`, `zsh`, `pwsh`). | Detected via `$SHELL` or process inspection |
| **`IS_WSL`** | Integer (`0` or `1`) | `.shell_init.sh` | Fast flag indicating execution inside WSL2. | `1` if `$WSL_DISTRO_NAME` is non-empty |
| **`WSL_USER`** | String | `.shell_common.sh` | Linux username used for cross-host UNC bridging. | Captured from `$USER` |

---

## 2. Debugging & Performance Flags

| Variable Name | Accepted Values | Purpose |
| :--- | :--- | :--- |
| **`DOTFILES_DEBUG`** | `true`, `false` (or empty) | When set to `true`, prints verbose diagnostic traces during shell loader startup. |
| **`DOTFILES_PROFILE`** | `1`, `0` (or empty) | When set to `1` in Zsh, enables `zprof` function profiling and prints execution report. |
| **`DOTFILES_PWSH_DEBUG`**| `1`, `0` | When set to `1` in PowerShell, prints verbose loader information to stderr. |
| **`NO_NETWORK`** | `1`, `0` | When set to `1` during `bootstrap.sh`, skips downloading external packages (`oh-my-posh`, `zsh`). |

---

## 3. Recursion & Loop Guards

| Guard Variable | Environment | Enforcing Mechanism |
| :--- | :--- | :--- |
| **`DOTFILES_WINDOWS_BOOTSTRAP_LOADING`** | PowerShell (Windows) | Prevents infinite loop if the Windows profile re-sources itself. |
| **`DOTFILES_PWSH_PROFILE_LOADING`** | PowerShell (Repo Profile) | Prevents re-entry when subshells or background jobs run within PowerShell. |
| **`DOTFILES_MODULAR_PWSH_LOADING`** | PowerShell (`integration.ps1`) | Guards modular configuration loader dispatch. |
| **`DOTFILES_VSCODE_SHELL_INTEGRATION_LOADED`** | Bash, Zsh, PowerShell | Ensures VS Code terminal shell integration runs exactly once per process. |

---

## 4. MCP & Secret Variables

| Variable Name | Configured In | Purpose |
| :--- | :--- | :--- |
| **`SOPS_AGE_KEY_FILE`** | Shell environment | Path to the Age private key (defaults to `~/.config/sops/key.txt`). |
| **`MCP_GATEWAY_URL`** | `mcp/.env` | HTTP/SSE endpoint for Model Context Protocol gateway. |
| **`MCP_BRIDGE_SCRIPT_PATH`**| `mcp/.env` | Local filesystem path to `mcp_stdio_bridge.js`. |
