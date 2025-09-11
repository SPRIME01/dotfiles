## 🔐 Step 1: Generate Your ED25519 Key Pair

This creates your personal identity for SSH authentication.

```bash
ssh-keygen -t ed25519 -C "samuel@yourdomain" -f ~/.ssh/id_ed25519
```

- `-t ed25519`: Specifies the key type
- `-C`: Adds a comment (usually your email or hostname)
- `-f`: Sets the filename (default is `~/.ssh/id_ed25519`)
- You’ll be prompted for a passphrase—optional but recommended

Result:
- `id_ed25519`: Your private key (keep secret!)
- `id_ed25519.pub`: Your public key (share with remote hosts)

---

## 🖥️ Step 2: Configure SSH Host Keys (for servers you want to accept connections)

On each host you want to SSH _into_, generate host keys:

```bash
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
```

Then update `/etc/ssh/sshd_config`:

```text
HostKey /etc/ssh/ssh_host_ed25519_key
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

Restart the SSH daemon:

```bash
sudo systemctl restart sshd
```

---

## 📁 Step 3: Set Up Your `~/.ssh/config` for Client Connections

This makes your SSH usage modular and alias-friendly:

```text
Host homestation
    HostName 192.168.1.100
    User samuel
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    Port 22
```

You can now connect with:

```bash
ssh homestation
```

---

## 🔄 Step 4: Share Your Public Key with Remote Hosts

Use `ssh-copy-id` (Linux/macOS):

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub samuel@192.168.1.100
```

Or manually append your public key to the remote host’s `~/.ssh/authorized_keys`.

On Windows, use PowerShell:

```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh samuel@192.168.1.100 "cat >> ~/.ssh/authorized_keys"
```

---

## 🧪 Step 5: Test and Harden

- Test with `ssh -v homestation` for verbose output
- Use `ssh-keygen -lf ~/.ssh/id_ed25519` to verify fingerprints
- Audit permissions:
  - `~/.ssh` should be `700`
  - `authorized_keys` and private keys should be `600`

---

## 🧰 Bonus: Modularize for Automation

Given your provisioning flow, consider wrapping this into a PowerShell function:

```powershell
function New-SSHKeyPair {
    param (
        [string]$KeyName = "id_ed25519",
        [string]$Comment = "$env:USERNAME@$(hostname)"
    )
    ssh-keygen.exe -t ed25519 -C $Comment -f "$env:USERPROFILE\.ssh\$KeyName"
}
```


