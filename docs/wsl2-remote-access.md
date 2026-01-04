# WSL2 Remote Access Setup Guide

## Overview

This guide covers how to set up secure remote SSH access to your WSL2 environment using Tailscale SSH and configure VS Code Remote-SSH for seamless development.

**Key Features:**
- 🔒 Secure access via Tailscale (no key management needed)
- 🔄 Fully idempotent and self-healing
- 🤖 Automatic machine auditing
- 🖥️ VS Code Remote-SSH integration
- 🌐 Works from anywhere on your tailnet

---

## Quick Start

```bash
# Run the setup script (auto-detects and fixes issues)
bash scripts/setup-wsl2-remote-access.sh

# Or just audit without making changes
bash scripts/setup-wsl2-remote-access.sh --audit
```

That's it! The script will:
1. Install Tailscale in WSL2 if needed
2. Enable Tailscale SSH
3. Configure VS Code Remote-SSH in `~/.ssh/config`
4. Verify everything works

---

## What Gets Configured

### 1. Tailscale in WSL2

The script ensures Tailscale is installed **inside WSL2** (not just using the Windows client). This is critical because:
- WSL2 needs its own Tailscale daemon to accept SSH connections
- The Windows Tailscale client doesn't expose WSL2 to your tailnet
- SSH connections must terminate in the WSL2 environment

**Installed at:** `/usr/bin/tailscale` (not `/mnt/c/...`)

### 2. Tailscale SSH

Enables SSH access via Tailscale with:
```bash
tailscale up --ssh --advertise-tags=tag:homelab-wsl2
```

**Benefits:**
- No SSH keys to manage
- No password prompts
- End-to-end encrypted via WireGuard®
- Works through NAT/firewalls
- Automatic authentication via Tailscale

### 3. VS Code Remote-SSH Configuration

Creates an entry in `~/.ssh/config`:

```ssh-config
# WSL2 via Tailscale - Auto-configured by dotfiles
Host wsl-<hostname>
    HostName <tailscale-hostname>.ts.net.
    User <username>
    # Tailscale handles authentication - no keys needed
```

**Example:**
```ssh-config
Host wsl-Yoga7i
    HostName yoga7i-1.chronicle-porgy.ts.net.
    User sprime01
```

---

## Machine Audit

The script performs comprehensive health checks:

| Check | Description |
|-------|-------------|
| ✅ WSL2 Environment | Verifies `WSL_DISTRO_NAME` is set |
| ✅ Tailscale Installation | Checks for native WSL2 installation (not Windows interop) |
| ✅ Tailscaled Daemon | Ensures daemon is running in WSL2 |
| ✅ Tailscale SSH | Verifies SSH capability is enabled |
| ✅ SSH Directory | Checks `~/.ssh` exists with correct permissions |
| ✅ VS Code Config | Validates `~/.ssh/config` has entry for this machine |
| ✅ File Permissions | Ensures SSH config is 600 or 644 |

**View audit status:**
```bash
bash scripts/setup-wsl2-remote-access.sh --audit
```

**Sample output:**
```
ℹ️  === Machine Configuration Audit ===

✅ WSL2 detected: Ubuntu
✅ Tailscale installed in WSL2: 1.56.1
  → Binary at: /usr/bin/tailscale
✅ Tailscaled daemon running in WSL2
✅ Tailscale SSH enabled
  → Hostname: yoga7i-1
  → IP: 100.111.106.10
✅ ~/.ssh directory exists
✅ VS Code Remote-SSH configured for wsl-Yoga7i
✅ SSH config has correct permissions (600)

✅ All checks passed! Your machine is properly configured.
```

---

## Using VS Code Remote-SSH

### First-Time Setup

1. **Install Remote - SSH Extension**
   - Open VS Code on Windows (or any device on your tailnet)
   - Press `Ctrl+Shift+X` (Extensions)
   - Search for "Remote - SSH" (by Microsoft)
   - Click Install

2. **Connect to WSL2**
   - Press `F1` (or `Ctrl+Shift+P`)
   - Type: `Remote-SSH: Connect to Host`
   - Select `wsl-<hostname>` from the list (e.g., `wsl-Yoga7i`)
   - New window opens → VS Code installs server components
   - Trust the host when prompted

3. **Start Developing!**
   - Open folders in WSL2: `File → Open Folder`
   - Open integrated terminal: `` Ctrl+` ``
   - Install extensions in WSL2 context

### Quick Reconnect

**Method 1: Remote Icon**
- Click green remote icon (bottom-left corner)
- Select `Connect to Host...`
- Choose `wsl-<hostname>`

**Method 2: Command Palette**
- `F1` → `Remote-SSH: Connect to Host`
- Select your host

**Method 3: Recent Hosts**
- `F1` → `Remote-SSH: Connect to Recent`
- Pick from history

### Advanced: SSH Config Location

Your config is at: `~/.ssh/config` (in WSL2)

**View it:**
```bash
cat ~/.ssh/config
```

**Edit manually if needed:**
```bash
nano ~/.ssh/config
```

---

## Script Usage

### Commands

```bash
# Auto mode (default) - audit and fix issues
bash scripts/setup-wsl2-remote-access.sh

# Audit only - show status without changes
bash scripts/setup-wsl2-remote-access.sh --audit

# Force setup - reconfigure even if working
bash scripts/setup-wsl2-remote-access.sh --setup

# Help
bash scripts/setup-wsl2-remote-access.sh --help
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TAILSCALE_AUTH_KEY` | Auth key for non-interactive setup | None (interactive) |
| `DOTFILES_ROOT` | Dotfiles repository location | Auto-detected |

**Non-interactive setup:**
```bash
export TAILSCALE_AUTH_KEY="tskey-auth-..."
bash scripts/setup-wsl2-remote-access.sh
```

---

## Connecting from Other Devices

Once configured, you can SSH from **any device on your tailnet**:

### From Command Line

```bash
# Using MagicDNS (recommended)
ssh username@hostname

# Using Tailscale IP
ssh username@100.x.x.x

# Example
ssh sprime01@Yoga7i
ssh sprime01@100.111.106.10
```

### From VS Code on Another Machine

1. **Sync SSH config** to other machines via:
   - Dotfiles sync (if using chezmoi)
   - Manual copy of `~/.ssh/config`
   - Recreate entry with same Host name

2. **Install Tailscale** on the client machine

3. **Authenticate** to your tailnet

4. **Connect** via Remote-SSH (same steps as above)

---

## Troubleshooting

### Issue: "Failed to retrieve Tailscale hostname"

**Cause:** Tailscale not authenticated or daemon not running

**Fix:**
```bash
# Check status
tailscale status

# If logged out, authenticate
sudo tailscale up --ssh --advertise-tags=tag:homelab-wsl2

# Verify
bash scripts/setup-wsl2-remote-access.sh --audit
```

### Issue: "Tailscale command is from Windows (not WSL2)"

**Cause:** WSL2 is using Windows Tailscale via interop (won't work for SSH)

**Fix:**
```bash
# Install in WSL2
bash scripts/install-tailscale.sh

# Verify path is NOT /mnt/c/...
which tailscale
# Should show: /usr/bin/tailscale
```

### Issue: VS Code connection hangs or times out

**Causes & Fixes:**

1. **Tailscaled not running in WSL2**
   ```bash
   sudo systemctl start tailscaled
   ```

2. **SSH not enabled**
   ```bash
   sudo tailscale up --ssh
   ```

3. **Wrong hostname in config**
   ```bash
   # Rerun setup to fix
   bash scripts/setup-wsl2-remote-access.sh --setup
   ```

4. **Client not on tailnet**
   - Ensure client device is authenticated to Tailscale
   - Check: `tailscale status` on client

### Issue: "Permission denied (publickey)"

**Cause:** Trying to use regular SSH instead of Tailscale SSH

**Fix:** Ensure you're connecting through Tailscale, not regular SSH:
- Client must be on the tailnet
- Use Tailscale hostname or IP (not localhost/LAN IP)
- Tailscale SSH doesn't use keys (it handles auth automatically)

### Issue: Audit shows old hostname

**Fix:** Re-run setup to update:
```bash
bash scripts/setup-wsl2-remote-access.sh --setup
```

The script backs up old config and creates a fresh entry.

---

## Integration with Dotfiles

### Justfile Integration

Add to your `justfile`:

```just
# Setup WSL2 remote access via Tailscale
setup-wsl2-remote:
    bash scripts/setup-wsl2-remote-access.sh

# Audit remote access configuration
audit-remote:
    bash scripts/setup-wsl2-remote-access.sh --audit
```

**Usage:**
```bash
just setup-wsl2-remote
just audit-remote
```

### Bootstrap Integration

The setup script is idempotent and can be run during bootstrap:

```bash
# In bootstrap.sh or install.sh
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    bash scripts/setup-wsl2-remote-access.sh
fi
```

### Component Tracking

The `components.yaml` includes:

```yaml
- id: tailscale_ssh
  description: WSL2 remote access via Tailscale SSH (preferred)
  script: scripts/setup-wsl2-remote-access.sh
  depends_on: []
  idempotent: true
  tests: [test/test-wsl2-remote-access.sh]
```

---

## Architecture Details

### Why Tailscale SSH?

**Replaced:** npiperelay/socat bridge to Windows ssh-agent

**Benefits:**
- ✅ No bridge complexity or race conditions
- ✅ No SSH key management
- ✅ Works across all platforms consistently
- ✅ Automatic end-to-end encryption
- ✅ NAT traversal built-in
- ✅ Zero-trust security model

### How It Works

```
┌─────────────────┐         ┌──────────────────┐
│  VS Code Client │         │  WSL2 Instance   │
│  (Windows/Mac)  │         │                  │
│                 │         │  tailscaled      │
│  Remote-SSH     │────────▶│  ├─ SSH Server   │
│  Extension      │  VPN    │  └─ Your Code    │
│                 │ (WG®)   │                  │
└─────────────────┘         └──────────────────┘
        │                            ▲
        │                            │
        └──────────────┬─────────────┘
                 Tailscale Network
               (End-to-End Encrypted)
```

### Hostname Resolution

The script uses multiple fallback methods to get your Tailscale hostname:

1. **JSON + jq** (best): `tailscale status --self --json | jq -r '.Self.DNSName'`
2. **JSON + grep**: Parse JSON output manually
3. **Status grep**: Extract from `tailscale status` output
4. **Short name**: Use machine name from status
5. **IP fallback**: Use Tailscale IP address if all else fails

This ensures reliability across different Tailscale versions and system configurations.

---

## Security Considerations

### Authentication

- **No passwords required** - Tailscale handles auth
- **No SSH keys needed** - Keys managed by Tailscale
- **Certificate-based** - Tailscale issues short-lived certs
- **MFA enforced** - If enabled in Tailscale admin console

### Network Security

- **Zero-trust model** - Every connection is authenticated
- **End-to-end encrypted** - WireGuard® protocol
- **No open ports** - No exposed SSH daemon on LAN
- **NAT traversal** - Direct peer-to-peer when possible

### Access Control

Configure in Tailscale admin console:
- ACL rules for SSH access
- User/group permissions
- Tag-based policies (e.g., `tag:homelab-wsl2`)
- Device approval requirements

---

## Testing

The setup is covered by automated tests:

```bash
# Run WSL2 remote access tests
bash test/test-wsl2-remote-access.sh

# Run full test suite
bash scripts/run-tests.sh
```

**Test coverage:**
- Script structure and error handling
- WSL environment detection
- Tailscale SSH setup function
- VS Code config generation
- Idempotency verification

---

## References

- [Tailscale SSH Documentation](https://tailscale.com/kb/1193/tailscale-ssh/)
- [VS Code Remote-SSH](https://code.visualstudio.com/docs/remote/ssh)
- [WSL2 Networking](https://docs.microsoft.com/en-us/windows/wsl/networking)
- [WireGuard Protocol](https://www.wireguard.com/)

---

## Changelog

### 2026-01-04 - Major Refactor
- ✅ Removed npiperelay/ssh-agent bridge (deprecated)
- ✅ Added automatic machine auditing
- ✅ Implemented idempotent VS Code SSH configuration
- ✅ Enhanced Tailscale hostname detection (5 fallback methods)
- ✅ Improved Windows vs WSL2 Tailscale detection
- ✅ Added comprehensive error handling
- ✅ Created full documentation

### Previous
- Basic Tailscale SSH setup
- Manual SSH config creation
