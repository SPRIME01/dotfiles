## Shared Shell Pipeline

Every interactive session starts in `.shell_common.sh`, which hands control to the modular loader at `shell/loader.sh`. From there the loader sources:

- `shell/common/environment.sh` for POSIX shells (bash + zsh)
- `shell/common/environment.ps1` for PowerShell via `PowerShell/Microsoft.PowerShell_profile.ps1`

This sequence also runs for non-interactive contexts that source `lib/env-loader.sh` or `PowerShell/Utils/Load-Env.ps1`, so anything you add to the shared environment modules becomes available to `just` recipes, automation scripts, and login shells alike.

## Adding Cross-Shell Tools

Shared environment files now sweep dedicated module directories on every load:

- POSIX shells: `shell/common/tools.d/sh/*.sh`
- PowerShell: `shell/common/tools.d/ps1/*.ps1`
- Headless loaders: `lib/env-loader.sh` and `PowerShell/Utils/Load-Env.ps1` source the same directories so CI and scripts see identical PATH updates.

### Quick scaffolding

Use the `just cross-shell-tool-add` recipe (wrapper around `scripts/add-cross-shell-tool.sh`) to scaffold matching modules for a new tool. The helper prompts for values, or you can provide them up front. For example, to register uv after installing it under `$HOME/.local/bin`:

```sh
TOOL_NAME=uv POSIX_PATH='$HOME/.local/bin' just cross-shell-tool-add
```

This command creates:

- `shell/common/tools.d/sh/uv.sh` for POSIX shells
- `shell/common/tools.d/ps1/uv.ps1` for PowerShell

Each snippet simply checks the install directory, uses the shared helpers to dedupe `PATH`, and is auto-sourced by every shell and automation context.

### Manual checklist

When you need custom behaviour beyond the generator, keep the layers aligned:

1. **POSIX shells** – add a guarded block or module that uses the `add_path_once` helper in `shell/common/environment.sh`. Only prepend when the directory exists to avoid PATH bloat.
2. **PowerShell** – mirror the change in `shell/common/environment.ps1` with `Add-PathIfMissing` so `$env:PATH` stays deduplicated.
3. **Headless loaders** – ensure `lib/env-loader.sh` and `PowerShell/Utils/Load-Env.ps1` include the logic so scripts that invoke them inherit the same environment without requiring an interactive shell.
4. **Shell-specific files** – only touch `shell/zsh/*.sh` or similar when a tool truly needs per-shell behaviour. Shared tools should live in the common modules above.

## Example: Volta

Volta now lives in the shared layers:

- `shell/common/environment.sh` checks for `$HOME/.volta/bin`, exports `VOLTA_HOME`, and prepends `"$VOLTA_HOME/bin"` to `PATH` with deduping.
- `shell/common/environment.ps1` performs the same check and updates `$env:PATH` when the directory exists.
- `lib/env-loader.sh` and `PowerShell/Utils/Load-Env.ps1` include matching logic so CI scripts or `just` targets that source them also see Volta.

With Volta centralized, `.shell_common.sh` and `zsh/path.zsh` no longer contain their own Volta snippets. Use this pattern for future tooling: update the shared environment first, then prune shell-specific leftovers.
