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

## Example: mise (Node.js and Tool Management)

Node.js version management is handled by **mise** (not Volta):

- `dot_mise.toml` defines global tool versions (node, pnpm, python, go, rust).
- `.shell_init.sh` activates mise via `mise activate zsh/bash`.
- Mise shims are added to PATH at `$HOME/.local/share/mise/shims`.
- Per-project versions can be set with `mise use node@18` which creates a local `.mise.toml`.

The shared environment files (`shell/common/environment.sh`, `lib/env-loader.sh`) no longer contain Volta-specific logic. Use this pattern for future tooling: configure in mise first, then verify shims are on PATH.
