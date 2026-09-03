# Design Decisions & Architectural Rationale

> **Layer:** 5 (Deep Explanation & Architectural Trade-offs)  
> **Audience:** Senior engineers, architects, and future maintainers seeking the technical "why"  
> **Evidence Standard:** Explicitly distinguishes **Confirmed Design Rationale** (derived from ADRs, commits, and comments) from **Inferred Rationale** (derived from code analysis).  

---

## 1. Summary of Major Design Decisions

| Decision | Primary Reason | Confirmed vs Inferred | Key Trade-off |
| :--- | :--- | :--- | :--- |
| **UNC paths instead of Windows symlinks** | Avoids Windows Developer Mode privilege requirement & cross-volume symlink corruption | **Confirmed** (ADRs & `ARCHITECTURE.md`) | Slight network overhead on cold file open vs total setup reliability |
| **Lazy-load proxies for PowerShell cmdlets** | Drops cold PowerShell startup from ~1200ms to <200ms | **Confirmed** (Commits & `ARCHITECTURE.md`) | Maintenance overhead of proxy stubs vs instant startup |
| **Streamlined `.shell_init.sh` replacing `.shell_common.sh`** | Resolves startup crashes and eliminates unsafe `eval` | **Confirmed** (`SHELL_MIGRATION.md`) | Advanced features moved to on-demand scripts |
| **Deny-by-default `.chezmoiignore`** | Prevents credentials and developer scratch files from leaking into `$HOME` | **Confirmed** (`.chezmoiignore` & tests) | Must explicitly whitelist new managed files |
| **Host separation for `Terminal-Icons`** | Prevents `Import-Clixml` XML parser crash in WSL2 `pwsh` | **Confirmed** (`ARCHITECTURE.md`) | Module cannot be loaded inside Linux `pwsh` |

---

## 2. Deep Dives: The Technical "Why"

### A. Why UNC Paths Instead of Windows Symlinks?
- **The Problem:** In Windows, creating symbolic links (`New-Item -ItemType SymbolicLink` or `mklink`) requires either an elevated Administrator command prompt or Windows Developer Mode enabled in the OS settings. Furthermore, NTFS symlinks pointing to ext4 WSL filesystems (`/home/...`) frequently corrupt across Windows reboots, WSL distribution upgrades, or drive re-indexing.
- **The Solution:** Windows PowerShell reaches across the hypervisor via Universal Naming Convention:
  `\\wsl.localhost\Ubuntu\home\sprime01\dotfiles` (falling back to `\\wsl$\Ubuntu\...`).
- **Confirmed Rationale:** Documented in `docs/reference/ARCHITECTURE.md`: "The repo stays in WSL... and is never symlinked into Windows."
- **Trade-off:** Reading files over the 9P network filesystem incurs a small sub-millisecond overhead per script read, but eliminates all administrative permission hurdles and path breakages.

---

### B. Why Lazy-Load Proxies for PowerShell Cmdlets?
- **The Problem:** `PowerShell/Modules/Aliases/Aliases.psm1` defines over 25 developer cmdlets and utility functions (`Get-GitStatus`, `Find-Directory`, `Stop-ProcessByPort`, etc.). Parsing the entire module at PowerShell startup takes 800ms – 1200ms, making new terminal tabs feel sluggish.
- **The Solution:** The repo profile declares thin function stubs:
  ```powershell
  function gs { Import-Module $aliasesModulePath -Force; Get-GitStatus @args }
  ```
- **Confirmed Rationale:** Documented in `PowerShell/Microsoft.PowerShell_profile.ps1`. The first call to any proxy loads `Aliases.psm1` into memory, which automatically replaces all stubs with real cmdlets. Subsequent calls run at native speed.
- **Consequence:** Cold startup drops to <200ms. Whenever a developer adds a new function to `Aliases.psm1`, they must run `updatealiases` to regenerate the proxy stubs.

---

### C. Why Replace `.shell_common.sh` with `.shell_init.sh`?
- **The Problem:** Historically, `.shell_common.sh` attempted to do everything on shell startup: complex `eval` blocks to detect script paths, auto-syncing environment variables to systemd on every tab open, running locale sanitizers, and printing dynamic ASCII banners. This caused random shell crashes and increased Zsh startup to 1.5–2.0 seconds.
- **The Solution:** Documented in `docs/work_summaries/SHELL_MIGRATION.md`. The startup path was split into:
  1. `.shell_init.sh`: Pure, error-resistant startup doing only essentials (paths, `.env`, aliases, `mise`, `direnv`). No unsafe `eval`.
  2. Background/On-demand tasks: Moved `auto-sync-env.sh` and `locale-sanitizer.sh` to explicit `just` recipes (`just sync-env`).
- **Confirmed Rationale:** Startup time dropped by 65–75%, and shell crashes reached zero.

---

### D. Why Deny-by-Default in `.chezmoiignore`?
- **The Problem:** Traditional dotfiles repositories track the root directory directly into `$HOME`. Any temporary file, `.env` file, git commit log, or experimental script created in the repository gets copied to the user's home folder upon running `chezmoi apply`.
- **The Solution:** `.chezmoiignore` begins with `*`:
  ```
  *
  !.chezmoiignore
  !.bashrc
  !.gitignore_global
  !.justfile
  !.mise.toml
  !.probe_file
  !.state_probe
  !.zshrc
  ```
- **Inferred & Verified Rationale:** Verified by `test/test-chezmoi-templates.sh`. This ensures mathematical safety: nothing touches the user's home folder unless explicitly reviewed and whitelisted in `.chezmoiignore`.

---

### E. Why Is `Terminal-Icons` Strictly Windows-Only?
- **The Problem:** `Terminal-Icons` is a PowerShell module that adds folder and file icons to directory listings. When executed inside WSL `pwsh`, it throws:
  `Import-Clixml: Name attribute for dictionary key is incorrectly specified`.
- **The Root Cause:** `Terminal-Icons` uses `Import-Clixml` to load cached theme data from `C:\Users\...`. Inside Linux `pwsh`, the .NET XML parser cannot resolve Windows-absolute paths, producing a null object that crashes PowerShell startup.
- **Confirmed Rationale:** Documented in `ARCHITECTURE.md` Section 3. The import was moved out of the repo profile and placed exclusively in the Windows bootstrap profile inside an `$IsWindows -and $PSVersionTable.PSEdition -eq 'Core'` block.

---

## 3. Technical Debt & Future Architecture

### 1. Coexistence of Modular Loaders and Fast Init
- **Observation:** Both `shell/loader.sh` (the 5-stage modular engine) and `.shell_init.sh` (the simplified fast init) exist in the repository.
- **Current State:** `.zshrc` currently uses `.shell_init.sh` for fast startup, while `test/test-environment-loading.sh` tests both paths.
- **Recommendation:** Maintain `.shell_init.sh` as the default interactive path, while using `shell/loader.sh` for structured subshell invocations.

### 2. Manual Proxy Stub Maintenance
- **Observation:** Adding a cmdlet to `Aliases.psm1` requires running `updatealiases`.
- **Mitigation:** The post-commit hook at `scripts/git-hooks/post-commit` automatically detects modifications to `Aliases.psm1` and regenerates proxies.
