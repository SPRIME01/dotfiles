## Shared Shell Pipeline

Every interactive session starts in `.shell_common.sh`, which hands control to the modular loader at `shell/loader.sh`. From there the loader sources:

- `shell/common/environment.sh` for POSIX shells (bash + zsh)
- `shell/common/environment.ps1` for PowerShell via `PowerShell/Microsoft.PowerShell_profile.ps1`

This sequence also runs for non-interactive contexts that source `lib/env-loader.sh` or `PowerShell/Utils/Load-Env.ps1`, so anything you add to the shared environment modules becomes available to `just` recipes, automation scripts, and login shells alike.

## Adding Cross-Shell Tools

When you need a tool on every shell, follow this checklist:

1. **POSIX shells** – add a guarded block to `shell/common/environment.sh`. Prefer the existing `case ":$PATH:"` pattern to avoid duplicates and only prepend when the directory exists.
2. **PowerShell** – mirror the change in `shell/common/environment.ps1`. Use the `$env:PATH -split ';'` approach already in the file to keep the Windows-style PATH deduplicated.
3. **Headless loaders** – keep `lib/env-loader.sh` and `PowerShell/Utils/Load-Env.ps1` in sync so scripts that run those helpers inherit the same environment without invoking an interactive shell.
4. **Shell-specific files** – only touch `shell/zsh/*.sh` or similar when a tool truly needs per-shell behavior. Shared tools should live in the common modules above.

## Example: Volta

Volta now lives in the shared layers:

- `shell/common/environment.sh` checks for `$HOME/.volta/bin`, exports `VOLTA_HOME`, and prepends `"$VOLTA_HOME/bin"` to `PATH` with deduping.
- `shell/common/environment.ps1` performs the same check and updates `$env:PATH` when the directory exists.
- `lib/env-loader.sh` and `PowerShell/Utils/Load-Env.ps1` include matching logic so CI scripts or `just` targets that source them also see Volta.

With Volta centralized, `.shell_common.sh` and `zsh/path.zsh` no longer contain their own Volta snippets. Use this pattern for future tooling: update the shared environment first, then prune shell-specific leftovers.
