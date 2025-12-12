# Secret Management Guide (Beginner-Friendly)

## 🔐 What is This?

Your dotfiles now use **encrypted secrets** so you can safely store API keys and passwords in git without exposing them. Think of it like a locked safe that only you have the key to.

## 🎯 Quick Start

### View Your Secrets

```bash
just secrets-help    # Show all available commands
just secrets-view    # See what's currently stored
```

### Add a New Secret

**Option 1: Provide the value directly**

```bash
just secrets-add GEMINI_API_KEY "your-api-key-here"
```

**Option 2: Be prompted for the value (more secure)**

```bash
just secrets-add GEMINI_API_KEY
# You'll be prompted to enter the value (it won't show on screen)
```

### Edit Secrets

```bash
just secrets-edit
```

This opens the encrypted file in your text editor (vim, nano, etc.). When you save and close, it's automatically re-encrypted.

### Remove a Secret

```bash
just secrets-remove OLD_API_KEY
```

### Use Secrets in Your Shell

```bash
# Decrypt secrets to .env (local use only)
just secrets-decrypt

# Now your shell can load them
source .env
```

## 📚 Common Workflows

### Workflow 1: Adding Your First API Key

```bash
# 1. Add the secret (you'll be prompted for the value)
just secrets-add GEMINI_API_KEY

# 2. Verify it was added
just secrets-view

# 3. Commit the encrypted file to git
git add .env.encrypted
git commit -m "chore: Add Gemini API key"
git push
```

### Workflow 2: Updating an Existing Secret

```bash
# 1. Edit the encrypted file
just secrets-edit

# 2. Find the line with your key and change the value
#    Example: GEMINI_API_KEY=old_value
#    Change to: GEMINI_API_KEY=new_value

# 3. Save and close (Ctrl+X in nano, :wq in vim)

# 4. Commit the change
git add .env.encrypted
git commit -m "chore: Update Gemini API key"
git push
```

### Workflow 3: Setting Up on a New Machine

```bash
# 1. Clone your dotfiles
git clone https://github.com/SPRIME01/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Make sure you have your age key
#    (Copy ~/.config/sops/key.txt from your old machine)

# 3. Decrypt secrets for local use
just secrets-decrypt

# 4. Done! Your .env file now has all your secrets
```

## 🔍 Understanding the Files

| File                     | What It Is                      | Safe for Git?              |
| ------------------------ | ------------------------------- | -------------------------- |
| `.env`                   | Plain text secrets (local only) | ❌ NO - gitignored         |
| `.env.encrypted`         | Encrypted secrets               | ✅ YES - commit this       |
| `.env.example`           | Template with no real values    | ✅ YES - already committed |
| `~/.config/sops/key.txt` | Your encryption key             | ❌ NO - keep private       |

## 🎓 Detailed Examples

### Example 1: Adding Multiple Secrets

```bash
# Add them one at a time
just secrets-add GEMINI_API_KEY
just secrets-add YOUCOM_API_KEY
just secrets-add SMITHERY_API_KEY

# Or edit the file directly to add many at once
just secrets-edit
# Add lines like:
# GEMINI_API_KEY=abc123
# YOUCOM_API_KEY=def456
# SMITHERY_API_KEY=ghi789
```

### Example 2: Viewing a Specific Secret

```bash
# View all secrets
just secrets-view

# View just one secret (using grep)
just secrets-view | grep GEMINI_API_KEY
```

### Example 3: Backing Up Your Encryption Key

```bash
# Your encryption key is at:
~/.config/sops/key.txt

# Back it up to a USB drive or password manager
# WITHOUT THIS KEY, YOU CAN'T DECRYPT YOUR SECRETS!

# To view your public key (safe to share):
age-keygen -y ~/.config/sops/key.txt
```

## 🚨 Important Safety Tips

1. **Never commit `.env`** - It's gitignored for a reason!
2. **Always commit `.env.encrypted`** - This is safe and should be in git
3. **Back up your age key** - Without it, you can't decrypt your secrets
4. **Use `just secrets-add`** - It prevents duplicate keys
5. **Test decryption** - After adding secrets, run `just secrets-decrypt` to make sure it works

## 🐛 Troubleshooting

### "Error: no matching creation rules found"

Your `.sops.yaml` file isn't configured correctly. This shouldn't happen, but if it does:

```bash
# Check if .sops.yaml exists
cat .sops.yaml

# It should have your age public key
age-keygen -y ~/.config/sops/key.txt
```

### "Error: failed to open input file"

Your age key is missing. Make sure it's at:

```bash
ls -la ~/.config/sops/key.txt
```

If it's missing, you need to copy it from another machine or generate a new one (but you'll lose access to old encrypted files).

### "Permission denied"

Fix file permissions:

```bash
chmod 600 ~/.config/sops/key.txt
chmod 600 .env
```

## 📖 Cheat Sheet

```bash
# Quick Reference
just secrets-help          # Show help
just secrets-view          # View all secrets
just secrets-add KEY       # Add new secret (prompted for value)
just secrets-add KEY VAL   # Add new secret with value
just secrets-remove KEY    # Remove a secret
just secrets-edit          # Edit in text editor
just secrets-encrypt       # Encrypt .env → .env.encrypted
just secrets-decrypt       # Decrypt .env.encrypted → .env
```

## 🎉 You're Ready!

You now have enterprise-grade secret management in your dotfiles. Your secrets are:

- ✅ Encrypted at rest
- ✅ Safe to commit to git
- ✅ Easy to manage with Just commands
- ✅ Portable across machines

Happy coding! 🚀
