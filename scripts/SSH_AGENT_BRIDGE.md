# SSH Agent Bridge

Unified mechanism to expose the Windows OpenSSH agent (or Pageant-like relay) to WSL2 shells using a stable Unix domain socket at:

```
$HOME/.ssh/agent.sock
```

## Components

| File | Purpose |
|------|---------|
| `setup-ssh-agent-bridge.sh` | Core idempotent bridge logic for WSL (socat + npiperelay) |
| `setup-ssh-agent-bridge.ps1` | Windows / PowerShell wrapper that can invoke the WSL setup |
| `systemd/ssh-agent-bridge.service` | Optional user service for persistent background bridge |

## Features

- Forces `SSH_AUTH_SOCK` each invocation (removes reliance on prior exports)
- Safe to source multiple times (restarts only when needed)
- Smart `npiperelay.exe` discovery (env override, Scoop, Chocolatey, PATH)
- Treats `ssh-add -l` exit codes 0 & 1 as healthy
- `--verbose`, `--dry-run`, `--status`, `--force-restart` flags and corresponding env vars
- Post-launch verification with fallback retry on next shell

## Quick Start (WSL bash / zsh)
Add to your shell init (`~/.bashrc` or `~/.zshrc`):
```bash
source "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh"
```
Optional verbose during troubleshooting:
```bash
export SSH_BRIDGE_VERBOSE=1
source "$HOME/dotfiles/scripts/setup-ssh-agent-bridge.sh"
```

## One-Off Manual Run
```bash
# Show status
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --status

# Start or ensure active with verbose logging
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --verbose

# Dry run (no socat spawned)
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --dry-run --verbose

# Force restart even if current socket appears healthy
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --force-restart --verbose
```

## PowerShell Wrapper (Windows host)
From a Windows PowerShell / pwsh terminal (outside WSL):
```powershell
pwsh -File $HOME/dotfiles/scripts/setup-ssh-agent-bridge.ps1 -Verbose
```
Dry run:
```powershell
pwsh -File $HOME/dotfiles/scripts/setup-ssh-agent-bridge.ps1 -Verbose -DryRun
```
The wrapper will call into WSL (via `wsl.exe`) and execute the bash bridge script.

## Environment Variables
| Variable | Effect |
|----------|--------|
| `SSH_BRIDGE_VERBOSE=1` | Enable verbose logging |
| `SSH_BRIDGE_DRY_RUN=1` | Skip spawning socat / npiperelay |
| `SSH_BRIDGE_FORCE_RESTART=1` | Force restart even if active |
| `NPIPERELAY_PATH` | Explicit path to `npiperelay.exe` |
| `SSH_AUTH_SOCK` | Always overwritten to `$HOME/.ssh/agent.sock` by script |

## Overriding `npiperelay.exe`
If autodiscovery fails:
```bash
export NPIPERELAY_PATH="/mnt/c/Tools/npiperelay.exe"
source ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --verbose
```

## Health Check
```bash
[[ -S "$SSH_AUTH_SOCK" ]] && ssh-add -l
```
Exit codes:
- 0: Agent reachable, keys loaded
- 1: Agent reachable, no keys yet (still good)
- 2+: Unreachable / broken pipe

## Troubleshooting
| Symptom | Action |
|---------|--------|
| `SSH_AUTH_SOCK` empty | Ensure script is sourced *after* any framework that resets env; add fallback export: `export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-$HOME/.ssh/agent.sock}"` |
| `ssh-add -l` hangs | Remove stale socket: `rm -f $SSH_AUTH_SOCK` then rerun script |
| `npiperelay.exe not found` | Install via Scoop (`scoop install npiperelay`) or set `NPIPERELAY_PATH` |
| Repeated restarts | Another process cleaning `~/.ssh`; check permissions and any cleanup hooks |

## Status & Force Restart
Built-in flags:
```bash
# Status only (does not modify anything)
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --status

# Force restart bridge
bash ~/dotfiles/scripts/setup-ssh-agent-bridge.sh --force-restart --verbose
```

## Security Notes
- Socket is created in `$HOME/.ssh`; ensure directory perms are `0700`.
- No world-readable exposure; `socat` listens only on a Unix domain socket path.

## systemd User Service (WSL)
Enable persistent background management (WSL distro must support systemd):
```bash
mkdir -p ~/.config/systemd/user
cp ~/dotfiles/scripts/systemd/ssh-agent-bridge.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent-bridge.service
systemctl --user status ssh-agent-bridge.service
```
Logs:
```bash
journalctl --user -u ssh-agent-bridge.service -f
```
Restart:
```bash
systemctl --user restart ssh-agent-bridge.service
```

## Future Ideas
- Optional telemetry / timing stats
- Automatic pruning of stale sockets on login
- Health watchdog / self-healing metrics

---
Generated documentation for the enhanced SSH agent bridge. Update as features evolve.
