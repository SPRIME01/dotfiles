# Setup Wizard

Central interactive orchestrator: `scripts/setup-wizard.sh`.

## Purpose
Guides user through configuring shells, VS Code settings, projects directory, PowerShell integration, SSH agent bridging, and optional Windows components. Tracks state for idempotent re-runs.

## Key Behaviors
- Detects prior runs via state file (`~/.dotfiles-state` by default).
- Offers retry of failed components and force reinstall.
- Uses component IDs aligned with `components.yaml`.
- Integrates logging (`lib/log.sh`) when available.

## Components Covered
Bash/Zsh config, Oh My Zsh/plugins, VS Code settings, PowerShell profile, projects setup, SSH bridge, Windows pwsh7 profile, Windows SSH agent.

See also:
- docs on WSL integration and SSH agent bridging: `README.md#how-to-use-remotely` and `README.md#🩺-health-check-doctor`
- PowerShell 7 setup notes in `README.md` (top section) and `PowerShell/Microsoft.PowerShell_profile.ps1`
## Idempotency
Each component checks state and skips unless forced or failed previously.

## Extending
1. Add component to `components.yaml`.
2. Implement script and tests.
3. Update wizard prompts and state handling.

## Non-Goals
- Deep dependency installation beyond minimal requirements.
- Secret management.

## Related Docs
- `docs/AI_INDEX.md`
- `docs/naming.md`
- `env-schema.md`
