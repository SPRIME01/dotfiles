# WSL2 ↔ Windows SSH Agent Bridge (Portable, Idempotent)

This package sets up a **portable**, **idempotent**, and **low‑debt** workflow where your **canonical ed25519 key** lives on **Windows**, is managed by the **Windows OpenSSH Agent**, and is **bridged into WSL2** via `npiperelay.exe` + `socat`.

## Contents

- `install-win-ssh-agent.ps1` — Windows installer (idempotent). Ensures ssh-agent is enabled, finds `npiperelay.exe`, generates/loads an **ed25519** key if needed, and writes a manifest for WSL.
- `install-wsl-agent-bridge.sh` — WSL2 installer (idempotent). Reads the Windows manifest, sets up the **bridge**, and inserts a managed startup block into your shell init files (replaced on each run).
- `rotate-ed25519.ps1` — Windows key rotation (safe + logged). Backs up old keys, generates a new **ed25519** key, loads it into the Windows agent, and prints the WSL path to the new public key.
- `tests/check-windows-agent.ps1` — Sanity checks on Windows.
- `tests/check-wsl-bridge.sh` — Sanity checks inside WSL2.
- `LICENSE` — MIT.

All scripts support **dry-run** and **verbose logging** where applicable, writing logs under:
- Windows: `%USERPROFILE%\.ssh\logs\...`
- WSL2: `~/.ssh/logs/...`

---

## Quick Start

### 1) Windows (PowerShell)

```powershell
# Dry-run (no changes)
.\install-win-ssh-agent.ps1 -DryRun -Verbose

# Real run
.\install-win-ssh-agent.ps1 -Verbose

# Optional: rotate key later
.\rotate-ed25519.ps1 -DryRun -Verbose
.\rotate-ed25519.ps1 -Verbose
```

> This writes `%USERPROFILE%\.ssh\bridge-manifest.json` with the discovered `npiperelay` path and host/user info.

### 2) WSL2 (Bash)

```bash
# Dry-run (no changes)
bash install-wsl-agent-bridge.sh --dry-run --verbose

# Real run
bash install-wsl-agent-bridge.sh --verbose
```

The installer replaces a managed **BEGIN/END** block in `~/.bashrc` and `~/.zshrc` so it never creates duplicates and is easy to remove.

### 3) Verify

In **Windows PowerShell**:
```powershell
ssh-add -l   # should list your ed25519 key
```

In **WSL2**:
```bash
ssh-add -l   # should match Windows
ssh -T git@github.com   # expect: "Hi <user>! ..."
```

---

## Design Principles (so it won’t create “tech debt”)

- **Idempotent**: Safe to rerun; shell init block is **replaced** between clear markers.
- **Single Source of Truth**: Windows manifest (`bridge-manifest.json`) records npiperelay path + metadata; WSL uses it.
- **No Private Keys in WSL**: Only the Windows agent holds the private key; WSL talks to it via a UNIX socket.
- **Logging & Dry-Run**: Predictable changes, easy troubleshooting.
- **Clean Uninstall**: Remove the managed block from your shell init and the bridge is gone.

---

## Uninstall

**WSL2:**
```bash
# Remove managed block from shell init (keep a backup of your rc files first if you like)
sed -i '/WSL→Windows SSH agent bridge (BEGIN)/, /WSL→Windows SSH agent bridge (END)/d' ~/.bashrc || true
sed -i '/WSL→Windows SSH agent bridge (BEGIN)/, /WSL→Windows SSH agent bridge (END)/d' ~/.zshrc 2>/dev/null || true

# Remove helper and socket
rm -f ~/.local/bin/win-ssh-agent-bridge ~/.ssh/agent.sock
```

**Windows (optional):**
```powershell
Stop-Service ssh-agent
Set-Service ssh-agent -StartupType Manual
```

---

## Notes

- If `npiperelay.exe` isn’t found, run the Windows installer again (or install via Scoop or Chocolatey).
- If you prefer **isolated keys**, skip the bridge and create a separate ed25519 key in WSL2; add both public keys to your remotes.


### 4) Deploy to all ~/.ssh/config hosts (verify + safe cleanup)

From **WSL2**, run:

```bash
bash deploy-ssh-key-to-hosts.sh --verbose
```

What it does (per host):
1. **Pushes** your current public key (from the Windows manifest) using `ssh-copy-id`.
2. **Verifies** that login works **non-interactively** with the **new key only**.
3. **Cleans up** old keys **only if** they exactly match the public keys found in your latest Windows backup directory created by `rotate-ed25519.ps1`.
   - It **backs up** the remote `authorized_keys` first (e.g., `authorized_keys.bak_YYYYmmdd_HHMMSS`).
   - It **does not** remove anyone else’s keys.

Quality-of-life flags:
- `--dry-run` see everything without changing anything
- `--verbose` detailed logs
- `--only "prod-*,db-*"` target by globs
- `--exclude "test-*"` skip by globs
- `--jobs 8` parallelize (uses `xargs -P` if available)
- `--timeout 8` per-host connect timeout
- `--resume` skip hosts already marked complete in the state file
- `--old-keys-dir /mnt/c/Users/<You>/.ssh/backup-2025...` explicitly set which backup folder to use

Logs & state:
- Logs: `~/.ssh/logs/deploy-ssh-key_*.log`
- State (resumable): `~/.ssh/logs/deploy-ssh-key_state.json`


---

## Extras for Zero Maintenance

- `preflight.sh` — quick sanity checks (manifest, npiperelay, agent keys, hosts).
- `list-hosts.sh` — preview which `Host` aliases will be targeted.
- `full-rotate-and-deploy.sh` — one-command orchestrator:
  - rotates the Windows ed25519 key (PowerShell),
  - (optionally) ensures your WSL bridge is installed,
  - deploys to all hosts with verification + safe cleanup.
- `uninstall-wsl-bridge.sh` and `uninstall-windows.ps1` — clean removal.
- `VERSION` — current package version: **1.1.0**.

### One-command flow
```bash
# dry-run everything end-to-end
bash full-rotate-and-deploy.sh --dry-run --verbose

# real run with filters and parallelism
bash full-rotate-and-deploy.sh --only "prod-*,db-*" --jobs 8 --verbose
```

### Preflight & Preview
```bash
bash preflight.sh
bash list-hosts.sh
```

### Clean uninstall
```bash
bash uninstall-wsl-bridge.sh
# On Windows (optional):
powershell.exe -File uninstall-windows.ps1 -DisableAgent
```

This package is intentionally **offline-first** and **self-contained** to avoid constant updates. If your environment changes (e.g., different `npiperelay.exe` path), just re-run `install-win-ssh-agent.ps1` to refresh the manifest—everything else reads from that source of truth.
