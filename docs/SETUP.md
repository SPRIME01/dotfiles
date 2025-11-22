# Dotfiles Security & Tooling Setup

## 🔒 Security Remediation (Completed)

### Phase 1: Critical Issues Fixed

✅ **Removed exposed credentials** from working tree:

- API keys (Gemini, You.com, Smithery)
- MCP admin password

✅ **Updated `.gitignore`** to prevent future exposure:

- `.env` files
- MCP backup files (`mcp/backups/`, `*_Settings_*.json`)

✅ **Hardened PowerShell**:

- Changed execution policy from `Bypass` to `RemoteSigned`

✅ **Secured installers**:

- Replaced `curl | sh` with checksum-verified installer
- Added `lib/secure-install.sh` for safe downloads

### ⚠️ Required Actions

**You must complete these steps:**

1. **Rotate all exposed credentials:**

   - Google Gemini API: https://console.cloud.google.com/apis/credentials
   - You.com API: https://you.com/dashboard
   - Smithery API: https://smithery.ai/settings
   - MCP Admin Password: Generate new secure password

2. **Create new `.env` file:**

   ```bash
   cp .env.example .env
   # Edit .env with your NEW rotated keys
   chmod 600 .env
   ```

3. **Clean git history** (MCP backups are in commit `6decabd0`):

   ```bash
   # Option A: Using git-filter-repo (recommended)
   git filter-repo --path mcp/backups/ --invert-paths --force

   # Then force push to all remotes
   git push origin --force --all
   git push origin --force --tags
   ```

4. **Run secret scanner:**
   ```bash
   detect-secrets scan > .secrets.baseline
   detect-secrets audit .secrets.baseline
   ```

---

## 🚀 Modern Tooling Setup

### Devbox (Jetify)

**Devbox** provides a reproducible development environment with all necessary tools.

#### Install Devbox:

```bash
curl -fsSL https://get.jetify.com/devbox | bash
```

#### Start Devbox shell:

```bash
cd ~/dotfiles
devbox shell
```

This automatically installs:

- `chezmoi` - Dotfile management
- `just` - Task runner
- `mise` - Tool version manager
- `sops` - Secret encryption
- `age` - Encryption tool
- `direnv` - Environment loader
- `git`, `shellcheck`, `shfmt`, `jq`, `ripgrep`, `fd`, `gh`

#### Devbox scripts:

```bash
devbox run bootstrap      # Initialize environment
devbox run lint           # Lint shell scripts
devbox run test           # Run tests
devbox run security-scan  # Scan for secrets
```

---

### Mise (Tool Version Manager)

**Mise** replaces Volta and provides unified tool version management.

#### Configuration:

Global config: `~/.config/mise/config.toml` (from `dot_mise.toml`)

Default tools installed:

- Node.js LTS
- Python 3.12
- Go (latest)
- Rust (stable)

#### Usage:

```bash
# Install all configured tools
mise install

# Add a tool globally
mise use -g node@20

# Add a tool to current project
mise use node@18

# List installed tools
mise list
```

#### Per-project setup:

Create `.mise.toml` in your project:

```toml
[tools]
node = "20"
python = "3.11"
```

Then in `.envrc`:

```bash
use mise
```

---

### Sops (Secret Management)

**Sops** encrypts secrets using your existing age key.

#### Setup (using your existing key):

1. **Update `.sops.yaml`** with your public key:

   ```bash
   # Extract your public key
   age-keygen -y ~/.config/sops/age/keys.txt

   # Update .sops.yaml with the output
   ```

2. **Encrypt secrets:**

   ```bash
   # Encrypt .env file
   sops -e .env > .env.encrypted

   # Decrypt when needed
   sops -d .env.encrypted > .env
   ```

3. **Edit encrypted files:**
   ```bash
   sops .env.encrypted
   ```

#### Workflow:

- Store `.env.encrypted` in git
- Keep `.env` in `.gitignore`
- Use `sops -d` in scripts to decrypt on-the-fly

---

### Chezmoi (Dotfile Management)

**Chezmoi** manages dotfiles across machines with templates.

#### Current setup:

- Templates: `dot_zshrc.tmpl`, `dot_bashrc.tmpl`, `dot_mise.toml`, `dot_justfile`
- Source: `~/dotfiles`

#### Usage:

```bash
# Apply dotfiles
chezmoi apply

# Preview changes
chezmoi diff

# Edit a managed file
chezmoi edit ~/.zshrc

# Add a new file
chezmoi add ~/.gitconfig
```

---

### Just (Task Runner)

**Just** provides convenient task automation.

#### Global tasks (from `~/.justfile`):

```bash
just bootstrap           # Initialize environment
just env-list            # List environment variables
just env-add KEY=VALUE   # Add environment variable
just env-remove KEY      # Remove environment variable
just sops-init           # Initialize sops (checks for existing key)
```

#### Project tasks (from `~/dotfiles/justfile`):

```bash
just test                # Run tests
just lint                # Lint shell scripts
just doctor              # Run diagnostics
just setup               # Interactive setup wizard
```

---

## 📋 Quick Start

### New Machine Setup:

1. **Install Devbox:**

   ```bash
   curl -fsSL https://get.jetify.com/devbox | bash
   ```

2. **Clone dotfiles:**

   ```bash
   git clone <your-repo> ~/dotfiles
   cd ~/dotfiles
   ```

3. **Start Devbox shell:**

   ```bash
   devbox shell
   ```

4. **Bootstrap environment:**

   ```bash
   devbox run bootstrap
   # or
   just bootstrap
   ```

5. **Setup secrets:**

   ```bash
   # Copy your age key to the new machine
   mkdir -p ~/.config/sops/age
   # ... copy keys.txt ...

   # Decrypt secrets
   sops -d .env.encrypted > .env
   chmod 600 .env
   ```

---

## 🔍 Verification

Run these commands to verify your setup:

```bash
# Check installed tools
chezmoi --version
just --version
mise --version
sops --version
age --version
direnv --version

# Verify mise tools
mise list

# Check for secrets
detect-secrets scan

# Run diagnostics
just doctor --strict
```

---

## 📚 Additional Resources

- [Devbox Documentation](https://www.jetify.com/devbox/docs/)
- [Mise Documentation](https://mise.jdx.dev/)
- [Sops Documentation](https://github.com/getsops/sops)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Just Documentation](https://just.systems/)

---

## 🐛 Troubleshooting

### Sops can't find age key:

```bash
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

### Mise tools not activating:

```bash
# Add to your shell rc file
eval "$(mise activate bash)"  # or zsh
```

### Direnv not loading:

```bash
direnv allow
```
