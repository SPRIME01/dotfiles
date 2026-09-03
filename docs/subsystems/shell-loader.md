# Subsystem Guide: Shell Initialization & Modular Loader Engine

> **Layer:** 3 (Subsystem Decomposition)  
> **Subsystem:** POSIX Shell Loader (`bash`, `zsh`)  
> **Primary Source Artifacts:** `.shell_init.sh`, `shell/loader.sh`, `shell/common/*`, `shell/platform-specific/*`  

---

## 1. Purpose
The Shell Initialization & Modular Loader Engine provides an error-resistant, fast (<250ms), and modular startup sequence for POSIX-compliant shells (Zsh and Bash) in Linux, WSL2, and macOS. It solves the fragility and latency of monolithic rc files by separating environment variables, aliases, functions, tool hooks, and platform-specific configurations into cleanly scoped scripts.

---

## 2. Responsibilities
- Deterministic derivation of `DOTFILES_ROOT` across Bash and Zsh without relying on `$PWD`.
- Loading essential cross-platform environment variables (`PROJECTS_ROOT`, `IS_WSL`, `WSL_USER`).
- Deduplicating and appending directory paths to `$PATH` via `lib/env-loader.sh` (`add_path_once`).
- Initializing project-scoped tool managers (`mise`, `direnv`).
- Setting up interactive shell amenities: history expansion, completion styles, and key bindings.
- Graceful degradation: failing safely if optional tools or platforms are missing.

---

## 3. Non-Responsibilities
- **PowerShell Startup:** Delegated entirely to `shell/loader.ps1` and `PowerShell/Microsoft.PowerShell_profile.ps1`.
- **Package Installation:** Does not install missing tools; only configures them if present on `$PATH`.
- **Systemd Environment Synchronization:** Handled on-demand by `scripts/sync-env-to-systemd.sh`.

---

## 4. Position in the System
- **Called by:**
  - `~/.zshrc` (managed by chezmoi from `dot_zshrc.tmpl`)
  - `~/.bashrc` (managed by chezmoi from `dot_bashrc.tmpl`)
  - Manual sourcing in subshells or test harnesses
- **Calls:**
  - `lib/platform-detection.sh`
  - `lib/env-loader.sh`
  - `shell/common/environment.sh`
  - `shell/common/aliases.sh`
  - `shell/common/functions.sh`
  - `shell/common/direnv.sh`
  - `shell/platform-specific/<linux|macos|windows>.sh`
  - `shell/<bash|zsh>/config.sh`

---

## 5. Core Abstractions
- **Dual Loader Architecture:**
  - **Fast Crash-Resistant Init (`.shell_init.sh`):** A compact (~200 lines) initialization path optimized for everyday shell speed. Contains lazy loaders (`__load_wsl_integration`, `__load_platform_config`) and avoids complex `eval`.
  - **Modular Loader Engine (`shell/loader.sh`):** The comprehensive, five-stage loader that reads structured components from `shell/common/`, `shell/platform-specific/`, and `shell/<shell>/`.
- **Safe Sourcing (`safe_source`):** A shell function wrapper ensuring that missing or unreadable files do not abort shell execution:
  ```bash
  safe_source() {
      local file="$1"
      if [[ -f "$file" && -r "$file" ]]; then
          source "$file"
      fi
  }
  ```

---

## 6. Internal Operation

### Startup Sequence
```
1. ~/.zshrc or ~/.bashrc triggered on terminal open
2. Sourcing of .shell_init.sh (or shell/loader.sh)
3. DOTFILES_ROOT derivation:
   - Bash: cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
   - Zsh:  eval 'DOTFILES_ROOT="$(cd "$(dirname "${(%):-%x}")" 2>/dev/null && pwd)"'
4. Environment Variables:
   - PROJECTS_ROOT=${PROJECTS_ROOT:-$HOME/projects}
   - IS_WSL detection via WSL_DISTRO_NAME
5. Tool Integrations:
   - mise: eval "$(mise activate zsh/bash)" (if present)
   - direnv: eval "$(direnv hook zsh/bash)" (quiet by default)
6. Sourcing of Common Aliases & Functions:
   - Navigation: .., ..., ...., cddot, projects
   - Git: gs, gd, glog, gp, gpu
   - Utilities: extract, mkcd, ports
7. Optional Profiling:
   - If DOTFILES_PROFILE=1, loads zsh/zprof and prints timing report
```

---

## 7. State
- **State Read:**
  - Environment variables: `$OSTYPE`, `$WSL_DISTRO_NAME`, `$BASH_VERSION`, `$ZSH_VERSION`, `$DOTFILES_PROFILE`.
  - Files: `.env` (via `lib/env-loader.sh`), `~/.zshrc.local` (for unversioned overrides).
- **State Modified:**
  - Exported variables: `DOTFILES_ROOT`, `PROJECTS_ROOT`, `IS_WSL`, `PATH`.
  - Shell options: `AUTO_CD`, `SHARE_HISTORY`, `HIST_IGNORE_DUPS`.

---

## 8. Lifecycle & Timing
- **Cold startup:** ~180ms – 250ms (measured via `tools/measure-startup.sh`).
- **P10k Instant Prompt:** Sourced at line 12 of `.zshrc` from `${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-*.zsh` to give an instantaneous shell appearance while plugins finish sourcing in background.

---

## 9. Failure Modes & Diagnostics

| Symptom | Probable Cause | Diagnostic Evidence | Recovery Path |
| :--- | :--- | :--- | :--- |
| `Command 'zsh' not found` | Zsh not installed on system | `which zsh` returns non-zero | Run `sudo apt update && sudo apt install -y zsh` or `install_zsh.sh` |
| `DOTFILES_ROOT` unset | Script sourced in unsupported subshell | `echo $DOTFILES_ROOT` is empty | Explicitly export `DOTFILES_ROOT="$HOME/dotfiles"` in `~/.zshrc.local` |
| Slow startup (>1.5s) | Redundant compinit or blocking network | `DOTFILES_PROFILE=1 zsh` shows slow function | Inspect zprof breakdown; ensure `skip_global_compinit=1` |
| Syntax error during sourcing | Bash trying to parse Zsh-specific syntax | Error points to `${(%):-%x}` | Ensure `.shell_init.sh` gates Zsh syntax inside `if [[ -n "$ZSH_VERSION" ]]` |

---

## 10. Extension Points
- **Local User Overrides:** Place custom unversioned aliases, functions, or exports in `~/.zshrc.local`. This file is sourced at the very end of `.zshrc` and is excluded from Git.
- **Adding Cross-Shell Tools:** Add standalone tool setup scripts in `shell/common/` or tool-specific snippets in `shell/platform-specific/`.

---

## 11. Source Trail
- `.shell_init.sh` — Fast shell initialization sequence
- `shell/loader.sh` — 5-stage modular shell configuration loader
- `.zshrc` / `dot_zshrc.tmpl` — Chezmoi Zsh configuration template
- `shell/common/environment.sh` — Shared POSIX environment variables
- `shell/common/aliases.sh` — Shared navigation and command aliases
- `shell/common/functions.sh` — Shared shell utility functions
- `test/test-environment-loading.sh` — Test verification for loader mechanics
- `test/test-no-deprecated-loaders.sh` — Test confirming legacy `scripts/load_env.sh` is not referenced
