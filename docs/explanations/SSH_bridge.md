# Windows + WSL2 SSH Agent Bridge (Best Practice)

Goal: keep your SSH private keys on Windows, use the Windows OpenSSH Agent, and access them from WSL2 via a Unix socket. This avoids copying keys into WSL and keeps permissions secure.

## Overview

- Keys live on Windows (C:\Users\<you>\.ssh).
- The Windows OpenSSH Agent holds your keys.
- A bridge exposes the Windows agent to WSL via a Unix socket (e.g., `~/.ssh/wsl-ssh-agent.sock`).
- WSL’s `~/.ssh/config` points to that socket using `IdentityAgent`.
- All files under `~/.ssh` in WSL are real files (no symlinks to `/mnt/c`) and have strict permissions.

If you already see `~/.ssh/wsl-ssh-agent.sock`, your bridge is likely installed and managed by your shell/systemd. Keep the path consistent with the config below.

---

## 1) Windows setup (PowerShell 7)

Enable and start the Windows OpenSSH Agent, add your key, and verify.

```powershell
# Enable/start the Windows OpenSSH agent
Get-Service ssh-agent
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# Add your key to the agent (adjust filename if different)
ssh-add $env:USERPROFILE\.ssh\id_ed25519

# Confirm the agent sees your key
ssh-add -l
```

Notes:
- If you use passphrases, you’ll be prompted once per session.
- Ensure your public key is added to your GitHub account:
  https://docs.github.com/en/authentication/connecting-to-github-with-ssh

---

## 2) WSL2 setup (Ubuntu)

Create a local `~/.ssh/config`, ensure strict permissions, and avoid symlinks to `/mnt/c`.

```bash
# Make sure ~/.ssh exists and is locked down
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Create a minimal, local config (do NOT symlink to /mnt/c)
cat > ~/.ssh/config <<'EOF'
Host github.com
  User git
  # Use the agent bridge socket provided by your WSL setup
  IdentityAgent ~/.ssh/wsl-ssh-agent.sock
  # Allow ssh to use agent-provided identities
  IdentitiesOnly no
EOF
chmod 600 ~/.ssh/config

# Ensure known_hosts is a local file (not a symlink)
# Copy it once from Windows if needed
if [ -L ~/.ssh/known_hosts ] || [ ! -f ~/.ssh/known_hosts ]; then
  cp /mnt/c/Users/<your-windows-user>/.ssh/known_hosts ~/.ssh/known_hosts 2>/dev/null || true
  chmod 600 ~/.ssh/known_hosts 2>/dev/null || true
fi

# Remove any symlinked private/public key files (we use the agent, not files)
[ -L ~/.ssh/id_ed25519 ] && rm ~/.ssh/id_ed25519
[ -L ~/.ssh/id_ed25519.pub ] && rm ~/.ssh/id_ed25519.pub
```

Replace `<your-windows-user>` with your Windows username (e.g., `sprim`).

---

## 3) Verify the bridge and GitHub access

```bash
# Bridge socket should exist
ls -l ~/.ssh/wsl-ssh-agent.sock

# Agent should list your Windows key(s)
ssh-add -l

# Test SSH to GitHub (expect "Hi <user>!")
ssh -T -v git@github.com

# Git should now work over SSH
git remote -v
git pull --tags origin main
```

If `ssh-add -l` says “The agent has no identities,” add your key in Windows (see step 1).

---

## 4) Keeping the bridge running

If the socket is missing after reboot, ensure your bridge is started automatically:
- Many setups use a small shell snippet (sourcing on login) or a systemd user service in WSL that spawns the bridge.
- Keep the socket path stable (`~/.ssh/wsl-ssh-agent.sock`) to match your `~/.ssh/config`.
- Common tools (examples to research and choose from):
  - wsl2-ssh-pageant
  - wsl-ssh-agent (npiperelay-based)
  Each provides instructions to install a Windows binary and start a bridge process in WSL.

Tip: If you change the socket path, update `IdentityAgent` accordingly.

---

## Troubleshooting

- Error: “Bad owner or permissions on /home/<you>/.ssh/config”
  - Cause: File owned by someone else, wrong mode, or it’s a symlink into `/mnt/c`.
  - Fix:
    ```bash
    chown -R "$USER":"$USER" ~/.ssh
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/config
    # Ensure config and known_hosts are real files, not symlinks to /mnt/c
    ```

- Error: “Permission denied (publickey)”
  - Check the agent sees your key:
    ```bash
    ssh-add -l
    ```
    If empty, add your key in Windows PowerShell:
    ```powershell
    ssh-add $env:USERPROFILE\.ssh\id_ed25519
    ssh-add -l
    ```
  - Ensure `~/.ssh/config` has:
    ```
    IdentityAgent ~/.ssh/wsl-ssh-agent.sock
    IdentitiesOnly no
    ```
  - Verify your Git remote uses SSH, not HTTPS:
    ```bash
    git remote -v
    # Should be git@github.com:owner/repo.git
    ```

- Error: Still using files under `/mnt/c`
  - Remove any symlinks in `~/.ssh` (especially `config`, `known_hosts`, `id_*`).
  - Recreate `config` and `known_hosts` as local files in WSL.
  - Do not reference `/mnt/c` paths in `~/.ssh/config` (e.g., `IdentityFile /mnt/c/...`).

- Socket issues (file missing or wrong path)
  - Confirm your bridge tool is running and creates `~/.ssh/wsl-ssh-agent.sock`.
  - If using a different socket path, update `IdentityAgent` to match.

- Quick bypass to isolate config problems
  ```bash
  # Test without your ~/.ssh/config
  ssh -F /dev/null -o IdentityAgent=~/.ssh/wsl-ssh-agent.sock -o IdentitiesOnly=no -T -v git@github.com
  ```

- Optional: DrvFs metadata (not recommended)
  - You can mount `/mnt/c` with `metadata` to improve permissions, but SSH StrictModes can still be fragile.
  - Best practice here is: keep `~/.ssh` files local to WSL and use the agent bridge.

---

## Security Notes

- Keep private keys on Windows only; don’t duplicate unless necessary.
- Never store secrets in shell history or scripts.
- Ensure `~/.ssh` perms: `700` for the dir, `600` for files.
- Avoid `IdentitiesOnly yes` with an agent bridge; it can prevent agent keys from being offered.

---

## Quick Reference

Windows (PowerShell):
```powershell
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
ssh-add $env:USERPROFILE\.ssh\id_ed25519
ssh-add -l
```

WSL (Ubuntu):
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cat > ~/.ssh/config <<'EOF'
Host github.com
  User git
  IdentityAgent ~/.ssh/wsl-ssh-agent.sock
  IdentitiesOnly no
EOF
chmod 600 ~/.ssh/config
[ -L ~/.ssh/known_hosts ] && rm ~/.ssh/known_hosts
cp /mnt/c/Users/<your-windows-user>/.ssh/known_hosts ~/.ssh/known_hosts 2>/dev/null || true
chmod 600 ~/.ssh/known_hosts 2>/dev/null || true
ssh-add -l
ssh -T -v git@github.com
```

---

## References

- GitHub Docs — Connecting with SSH:
  https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- Windows OpenSSH Agent:
  https://learn.microsoft.com/windows-server/administration/openssh/openssh_keymanagement
- WSL agent bridge tools (choose one and follow their README):
  - wsl2-ssh-pageant: https://github.com/BlackReloaded/wsl2-ssh-pageant
  - wsl-ssh-agent (npiperelay-based): https://github.com/rupor-github/wsl-ssh-agent
