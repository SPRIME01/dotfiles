# SSH Access for WSL2

> **📢 Migration Notice**: This project now uses **Tailscale SSH** instead of the legacy Windows SSH Agent Bridge. Tailscale SSH provides simpler setup, zero-config key management, and works across your entire tailnet.

## Quick Start

See the [Tailscale SSH Setup Guide](./tailscale-ssh-setup.md) for complete instructions.

```bash
# Install and configure Tailscale SSH
just install-tailscale

# Or run the setup script directly
bash scripts/setup-wsl2-remote-access.sh --tailscale
```

## Why Tailscale SSH?

| Feature              | Legacy npiperelay Bridge         | Tailscale SSH        |
| -------------------- | -------------------------------- | -------------------- |
| Setup complexity     | High (multiple tools)            | Low (single install) |
| Key management       | Manual                           | Automatic            |
| Cross-network access | No                               | Yes (via tailnet)    |
| Works with           | WSL2 only                        | Any device           |
| Dependencies         | socat, npiperelay, wsl-ssh-agent | tailscale only       |

## Legacy Documentation

The previous `npiperelay` + `socat` bridge approach has been deprecated. If you need to reference the old setup for troubleshooting existing installations, see the [Tailscale migration notes](./tailscale-ssh-setup.md#migration-from-legacy-ssh-bridge).

## Related

- [Tailscale SSH Setup](./tailscale-ssh-setup.md)
- [WSL2 Remote Access Script](../../scripts/setup-wsl2-remote-access.sh)
