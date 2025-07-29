Perfect. Here's a **comprehensive, battle-tested install & configuration doc** to get your **Windows SSH agent working inside WSL2** — from scratch, using `npiperelay`, `socat`, and `wsl-ssh-agent`. It includes installation steps, `.zshrc` configuration, and sanity checks.

You can save this as `docs/wsl2-windows-ssh-agent-bridge.md` in your dotfiles repo.

---

# 🛠 WSL2 + Windows SSH Agent Integration (Reproducible Guide)

## 🎯 Goal

Use **Windows-hosted SSH keys** securely inside **WSL2** without duplicating or exposing private keys.

---

## 🧩 Components

| Tool                      | Purpose                                                      |
| ------------------------- | ------------------------------------------------------------ |
| `OpenSSH agent (Windows)` | Manages your private keys securely with DPAPI                |
| `npiperelay`              | Bridges Windows named pipe to WSL2                           |
| `socat`                   | Creates Unix socket in WSL2, forwards to `npiperelay`        |
| `wsl-ssh-agent-relay`     | Prepares environment for SSH\_AUTH\_SOCK and lifecycle hooks |

---

## ⚙️ 1. Enable Windows OpenSSH Agent

Open **PowerShell (as Admin)**:

```powershell
# Enable OpenSSH Agent on startup
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# Add your key if needed
ssh-add C:\Users\<YourUser>\.ssh\id_rsa
```

Use `ssh-add -l` to verify the agent has keys loaded.

---

## 📦 2. Install Prerequisites

### In **WSL2**

```bash
sudo apt update
sudo apt install socat p7zip-full curl git
```

### In **Windows**

Install `npiperelay` using [Scoop](https://scoop.sh):

```powershell
scoop bucket add extras
scoop install npiperelay
```

This will put the binary at:

```
C:\Users\<You>\scoop\apps\npiperelay\0.1.0\npiperelay.exe
```

---

## 🚀 3. Install wsl-ssh-agent-relay (WSL)

```bash
git clone https://github.com/rupor-github/wsl-ssh-agent.git ~/.wsl-ssh-agent
cd ~/.wsl-ssh-agent
sudo ./install.sh
```

This sets up `/home/you/.ssh/wsl-ssh-agent.sock` as the target socket path.

---

## 🧠 4. Add to `.zshrc` or `.bashrc`

### ✅ Final Working Zsh/Bash Block

Add this **at the bottom** of your `~/.zshrc` or `~/.bashrc`:

```bash
# Start relay script
~/.local/bin/wsl-ssh-agent-relay start

# Define socket path and npiperelay location
export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"
NPIPERELAY="/mnt/c/Users/sprim/scoop/apps/npiperelay/0.1.0/npiperelay.exe"

# Helper to check if socket is live
is_socket_active() {
  [ -S "$SSH_AUTH_SOCK" ] && ssh-add -l >/dev/null 2>&1
}

# Launch socat bridge only if not already running
if ! is_socket_active; then
  rm -f "$SSH_AUTH_SOCK"
  setsid nohup socat \
    UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
    EXEC:"$NPIPERELAY //./pipe/openssh-ssh-agent" \
    >/dev/null 2>&1 &
fi
```

Then run:

```bash
source ~/.zshrc  # or ~/.bashrc
```

---

## ✅ 5. Verify Setup

Run:

```bash
ssh-add -l
```

Expected output: list of keys managed by the **Windows ssh-agent**, not WSL-local ones.

---

## 🛠 Optional: Manual Debug

You can test manually without `.zshrc`:

```bash
export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"
NPIPERELAY="/mnt/c/Users/sprim/scoop/apps/npiperelay/0.1.0/npiperelay.exe"
rm -f "$SSH_AUTH_SOCK"

socat -d -d \
  UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
  EXEC:"$NPIPERELAY //./pipe/openssh-ssh-agent"
```

Then in another terminal:

```bash
ssh-add -l
```

---

## 🔒 Security Note

* Your keys **never leave Windows**
* WSL simply **relays agent requests**
* Prevents managing keys in two places or exposing unencrypted keys in WSL2

---

## 💡 Tips

* Works seamlessly with **VSCode Remote - WSL**
* You can add a `wsl-ssh-init` helper script to toggle/debug the relay
* For persistent setup, consider a systemd user service if using `systemd` in WSL2

---

## 📁 Optional: Save as Shell Script

You can wrap the bridge logic into a reusable script:

**\~/.local/bin/wsl-ssh-bridge.sh**:

```bash
#!/bin/bash
export SSH_AUTH_SOCK="$HOME/.ssh/wsl-ssh-agent.sock"
NPIPERELAY="/mnt/c/Users/sprim/scoop/apps/npiperelay/0.1.0/npiperelay.exe"

if ! [ -S "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
  rm -f "$SSH_AUTH_SOCK"
  setsid nohup socat \
    UNIX-LISTEN:$SSH_AUTH_SOCK,fork \
    EXEC:"$NPIPERELAY //./pipe/openssh-ssh-agent" \
    >/dev/null 2>&1 &
fi
```

Then call it from `.zshrc`:

```bash
~/.local/bin/wsl-ssh-bridge.sh
```