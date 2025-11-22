# Tailscale SSH Setup for WSL2

This project uses Tailscale SSH to provide secure remote access to WSL2 instances across your tailnet.

## Overview

The dotfiles now include automated Tailscale installation and configuration via a `just` recipe. This replaces the previous Windows SSH Agent Bridge setup with a simpler, zero-config Tailscale SSH solution.

## Quick Start

1. **Install Tailscale** (if not already installed):

   ```bash
   just install-tailscale
   ```

2. **Verify the setup**:
   ```bash
   tailscale status
   ```

You should see your WSL2 instance listed with the `tag:homelab-wsl2` tag.

## Automated Authentication

To avoid interactive authentication during installation, you can provide a Tailscale Auth Key:

1. Generate a reusable auth key in the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)

   - Enable **Reusable** and **Ephemeral** (optional)
   - Add the tag `tag:homelab-wsl2` to the key

2. Set the environment variable:

   ```bash
   export TAILSCALE_AUTH_KEY="tskey-auth-..."
   ```

3. Run the installation:
   ```bash
   just install-tailscale
   ```

## Access Control

The installation automatically advertises the `tag:homelab-wsl2` tag, which is configured in your Tailscale ACL policy to allow:

- SSH access from `sprime01@gmail.com` as any user
- Automatic SSH key management via Tailscale

## Accessing Your WSL2 Instance

From any device in your tailnet:

```bash
# Using the MagicDNS hostname
ssh username@wsl-hostname

# Or using the Tailscale IP
ssh username@100.x.y.z
```

Tailscale handles key distribution automatically—no manual `ssh-copy-id` required.

## Configuration Details

The `scripts/install-tailscale.sh` script:

- Installs Tailscale using the official installer
- Runs `tailscale up` with:
  - `--ssh`: Enables Tailscale SSH
  - `--advertise-tags=tag:homelab-wsl2`: Applies the homelab tag
  - `--auth-key=$TAILSCALE_AUTH_KEY`: Uses the auth key if available

## Troubleshooting

### Authentication Required

If you didn't provide an auth key, you'll see a URL to authenticate in your browser:

```
To authenticate, visit: https://login.tailscale.com/a/...
```

### Check Tailscale Status

```bash
tailscale status
tailscale ip
```

### View Logs

```bash
sudo journalctl -u tailscaled -f
```

## Migration from Legacy SSH Bridge

The legacy Windows SSH Agent Bridge has been removed. If you were using it previously:

1. Remove any manual SSH keys from `~/.ssh/authorized_keys` on remote hosts (optional)
2. Tailscale SSH will handle authentication automatically
3. Update any scripts that referenced `just ssh-bridge-*` commands

## Further Reading

- [Tailscale SSH Documentation](https://tailscale.com/kb/1193/tailscale-ssh/)
- [Tailscale ACLs](https://tailscale.com/kb/1018/acls/)
- Your current ACL policy (see your original request for the full policy)
