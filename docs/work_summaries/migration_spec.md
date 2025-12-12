# Integrated Developer Environment Specification
## Cross-Platform Development with WSL + Windows

---

## 1. Shell Configuration

### Primary Environments
- **zsh** (WSL primary) → `oh-my-zsh` framework with direnv hook
- **bash** (WSL fallback) → Lightweight configuration with direnv hook
- **PowerShell** (Windows) → `oh-my-posh` theming engine

---

## 2. Configuration Management

### Chezmoi as Single Source of Truth
Manages all dotfiles and configurations across platforms:

- **Shell configs**: `.zshrc`, `.bashrc`, PowerShell `$PROFILE`
- **Development configs**: `.gitconfig`, `.ssh/config`, `.gitignore_global`
- **Tool configs**: `.mise.toml`, `.justfile` templates
- **Integration hooks**: direnv setup, PATH management

**Features:**
- Per-platform templating (Windows vs WSL differentiation)
- Automatic bootstrap scripts for new machine setup
- Reproducible environments across machines

---

## 3. SSH Management

### Unified Agent Architecture
**agent-bridge + npiperelay.exe** implementation:
- Single SSH agent shared between WSL and Windows
- `SSH_AUTH_SOCK` configured via chezmoi templates
- Keys remain in Windows secure storage
- No duplicate key management needed

---

## 4. Environment & Context Management

### Direnv for Project Isolation
Provides automatic, project-scoped environment loading:

**Shell Integration:**
```bash
# Managed by chezmoi in .zshrc/.bashrc
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"  # or bash
fi
```

**Project Configuration Pattern:**
```bash
# .envrc example
use mise        # Activate language runtimes
dotenv          # Load .env variables
```

**Security Model:**
- `.envrc` and `.env` globally gitignored
- Explicit `direnv allow` required per project
- Environment variables scoped to project directory

---

## 5. Runtime & Tool Management

### Mise for Version Control
Manages language/tool versions with automatic activation:

- **Config formats**: `.tool-versions` or `.mise.toml`
- **Supported tools**: UV/Python, Volta/Node, Go, Rust, etc.
- **Integration**: Hooks into direnv for seamless activation
- **Cross-platform**: Works identically in WSL and Windows

---

## 6. Task Automation

### Just as Task Runner
Standardizes commands across environments:

**Global Tasks** (`~/.justfile` - chezmoi managed):
```make
# Bootstrap development environment
bootstrap:
  chezmoi apply
  mise install
  echo "Environment ready"

# Common development tasks
lint:
  ruff check .

format:
  ruff format .
```

**Project Tasks** (local `justfile`):
```make
# Project-specific commands
dev:
  uvicorn app.main:app --reload

test:
  pytest -q --disable-warnings
```

**Integration Philosophy:**
- **mise** = *what* (tool versions)
- **just** = *how* (task execution)
- Together provide ergonomic, reproducible workflows

---

## 7. Filesystem Architecture

### Project Organization
- **Primary location**: WSL native filesystem for performance
- **Windows access**: Symbolic links expose projects to host tools
- **PATH configuration**: Projects folder added to PATH via chezmoi
- **Cross-platform commands**: `just` recipes work in all shells

---

## 8. Security & Best Practices

### Core Principles
1. **Sensitive Data Protection**
   - Global gitignore for `.env` and `.envrc`
   - Never commit credentials or secrets

2. **Scope Isolation**
   - direnv ensures environment variables are project-scoped
   - No global pollution of shell environment

3. **Secure Key Storage**
   - SSH keys remain in Windows secure agent
   - agent-bridge provides secure access from WSL

4. **Reproducibility**
   - chezmoi ensures consistent setup across machines
   - mise locks tool versions per project
   - just standardizes command interfaces

---

## 9. Bootstrap Workflow

### New Machine Setup
1. Install chezmoi and run initial apply
2. chezmoi provisions all dotfiles and configs
3. mise automatically installs defined tool versions
4. direnv hooks activate in configured shells (including PowerShell)
5. SSH agent bridge establishes Windows↔WSL connection

### PowerShell-Specific Setup
For PowerShell direnv integration:
- **WSL Interop**: Alias direnv to call WSL's direnv

### New Project Setup
1. Create project directory in WSL filesystem
2. Initialize `.envrc` with `use mise` and `dotenv`
3. Define tool versions in `.mise.toml`
4. Create project `justfile` for common tasks
5. Run `direnv allow` to activate environment

---

## Summary

This specification creates a unified development environment that:
- **Eliminates duplication** between Windows and WSL
- **Automates** environment setup and tool management
- **Standardizes** workflows across platforms and projects
- **Secures** sensitive data and SSH operations
- **Scales** from single developer to team environments
