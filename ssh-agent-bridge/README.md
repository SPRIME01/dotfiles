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
- `--jobs 8` parallelize (built-in bash job control; no external xargs dependency)
- `--timeout 8` per-host connect timeout
- `--resume` skip hosts already marked complete in the state file
- `--old-keys-dir /mnt/c/Users/<You>/.ssh/backup-2025...` explicitly set which backup folder to use
 - `--confirm-cleanup` actually remove old key blobs (without this flag cleanup is skipped for safety)

Logs & state:
- Logs: `~/.ssh/logs/deploy-ssh-key_*.log`
- State (resumable): `~/.ssh/logs/deploy-ssh-key_state.tsv` (TSV: host<TAB>status<TAB>timestamp)


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
# Human-readable checks
bash preflight.sh

# Strict mode (non-zero exit if any FAIL)
bash preflight.sh --strict

# Machine-readable summary
bash preflight.sh --json | jq .

# Minimal output (summary + advice only)
bash preflight.sh --summary-only

# Force color (if piping to less -R)
bash preflight.sh --color

# Convenience via just recipes
just ssh-bridge-preflight
just ssh-bridge-preflight-strict
just ssh-bridge-preflight-json

# Other quick views
bash status.sh          # summary (or: just ssh-bridge-status)
bash list-hosts.sh      # show parsed Host aliases
```

### Clean uninstall
```bash
bash uninstall-wsl-bridge.sh
# On Windows (optional):
powershell.exe -File uninstall-windows.ps1 -DisableAgent
```

This package is intentionally **offline-first** and **self-contained** to avoid constant updates. If your environment changes (e.g., different `npiperelay.exe` path), just re-run `install-win-ssh-agent.ps1` to refresh the manifest—everything else reads from that source of truth.

---

## Troubleshooting: Windows ↔ WSL Bridge Install Failure

If `just ssh-bridge-install-windows` failed with errors like:
```
Set-Service ssh-agent ... Access is denied
Start-Service ssh-agent ... Access is denied
ssh-add id_ed25519 -> Error connecting to agent: No such file or directory
```
and WSL reported:
```
socat not found. Install socat to enable SSH agent bridge.
```
follow the remediation below.

### 1) Root Cause
* Windows run was **non‑elevated**, so changing / starting the `ssh-agent` service failed.
* Because the service never started, `ssh-add` could not contact the agent (pipe missing).
* WSL lacked `socat`, so the UNIX socket bridge couldn’t be created.
* The ed25519 key already existed; the issue was connectivity, not key generation.

### 2) Fix (Windows – Elevated)
Run (or from WSL use `just ssh-bridge-remediate-windows` which launches a PowerShell that self‑elevates):
```powershell
# In an elevated PowerShell
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

$key = "$env:USERPROFILE\.ssh\id_ed25519"
if (-not (Test-Path $key)) { Write-Error "Missing key: $key"; exit 1 }
if (-not (ssh-add -l 2>$null | Select-String -SimpleMatch ((Get-Content "$key.pub") | Select-Object -First 1))) { ssh-add $key }
ssh-add -l

# Ensure/record npiperelay path + manifest
if (-not (Get-Command npiperelay.exe -ErrorAction SilentlyContinue)) { Write-Warning "Install npiperelay (scoop install npiperelay OR choco install npiperelay)" }
$np = (Get-Command npiperelay.exe -ErrorAction SilentlyContinue | Select -First 1 -Expand Source)
@{
  npiperelay_path     = $np                       # Windows path
  npiperelay_wsl      = ($np -replace '^([A-Za-z]):\\','/mnt/$([string]::ToLower($1))/') -replace '\\','/'  # WSL-mount path
  windows_user        = $env:USERNAME
  windows_host        = $env:COMPUTERNAME
  created_utc         = (Get-Date).ToUniversalTime().ToString('o')
  key_public_path_wsl = "/mnt/c/Users/$($env:USERNAME)/.ssh/id_ed25519.pub"
} | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 "$env:USERPROFILE\.ssh\bridge-manifest.json"
```

### 3) Fix (WSL)
```bash
sudo apt-get update
sudo apt-get install -y socat
test -f /mnt/c/Users/$USER/.ssh/bridge-manifest.json || { echo "Manifest missing; fix Windows first"; exit 1; }
bash ssh-agent-bridge/install-wsl-agent-bridge.sh --verbose
```

### 4) Verification
Windows:
```powershell
Get-Service ssh-agent | Select Status,StartType
ssh-add -l
Test-Path $env:USERPROFILE\.ssh\bridge-manifest.json
```
WSL:
```bash
ls -l ~/.ssh/agent.sock
ssh-add -l
ssh-keygen -lf /mnt/c/Users/$USER/.ssh/id_ed25519.pub
```
Expected: service Running (Automatic), identical key fingerprints, `agent.sock` exists, key listed in both environments.

### 5) Retry Script Snippets
Windows elevated one‑shot (already implemented as `remediate-windows-agent.ps1`):
```powershell
PowerShell -NoProfile -ExecutionPolicy Bypass -File remediate-windows-agent.ps1
```
WSL quick retry:
```bash
just ssh-bridge-remediate-wsl
```

### 6) Fallback (No Elevation)
Without elevation you cannot start/configure the Windows `ssh-agent` service. Do **not** generate a second private key in WSL (breaks single source of truth). Wait until you can elevate, then remediate.

### 7) Idempotency / Clean Re-run
* Windows remediation is safe: it only loads an existing key and overwrites the manifest when requested.
* WSL installer replaces its managed block each run; no duplicate lines.
* To reset: delete the manifest (`del %USERPROFILE%\.ssh\bridge-manifest.json`) and rerun the Windows remediation; remove `~/.ssh/agent.sock` + `~/.local/bin/win-ssh-agent-bridge` then reinstall on WSL.

See also the helper Just recipes:
```bash
just ssh-bridge-remediate-windows   # Elevate + fix Windows side
just ssh-bridge-remediate-wsl       # Install socat + reinstall bridge
```

