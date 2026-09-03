# How-To: Manage Encrypted Secrets with SOPS

> **Type:** Diátaxis How-To Guide (Goal-oriented, practical task)  
> **Goal:** Encrypt, edit, and safely commit API keys and tokens using SOPS and Age  
> **Prerequisites:** `sops` and `age` installed; Age private key at `~/.config/sops/key.txt`  

---

## 1. Prerequisites Check

Confirm that `sops` and `age` are available on your `$PATH`:
```bash
sops --version
age --version
```

Confirm that your private key exists:
```bash
ls -l ~/.config/sops/key.txt
# Permissions must be -rw------- (0600)
```

---

## 2. Interactive Secret Editing

To view or edit `.secrets.json`:
```bash
just secrets-edit
```
*What happens:*
1. SOPS decrypts the ciphertext in memory using `~/.config/sops/key.txt`.
2. Launches your configured `$EDITOR` (e.g. `vim`, `nano`, or `code --wait`).
3. Upon saving and exiting, SOPS automatically re-encrypts the file with the Age public key declared in `.sops.yaml`.

---

## 3. Viewing Decrypted Secrets in Plaintext

To inspect decrypted values without opening an editor:
```bash
just secrets-view
```

To view a single secret key:
```bash
sops -d --extract '["GEMINI_API_KEY"]' .secrets.json
```

---

## 4. Adding a New Secret Directly via CLI

```bash
just secrets-add SMITHERY_API_KEY="your-token-here"
```

---

## 5. Encrypting a Raw File

If you have a local `.env` file that you want to encrypt for storage:
```bash
sops -e .env > .env.encrypted
```

To decrypt back to `.env`:
```bash
sops -d .env.encrypted > .env
chmod 600 .env
```

---

## 6. Source Trail
- `.sops.yaml`
- `.secrets.json`
- `justfile`
- `docs/how-to/SECRET_MANAGEMENT.md`
