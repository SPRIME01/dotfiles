# Dotfiles Project - Complete How-To Guide

Welcome to the comprehensive guide for the modern dotfiles project! This documentation provides step-by-step instructions for setup, usage, and maintenance of your cross-platform shell configuration system.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation & Setup](#installation--setup)
3. [Command Reference](#command-reference)
4. [Platform-Specific Guides](#platform-specific-guides)
5. [Advanced Configuration](#advanced-configuration)
6. [State Management & Idempotency](#state-management--idempotency)
7. [Troubleshooting](#troubleshooting)
8. [Development & Testing](#development--testing)

## Quick Start

### Prerequisites

- **Just** command runner: [Install Just](https://github.com/casey/just#installation)
- **Git** for repository management
- **Zsh** or **Bash** shell (Zsh recommended)
- **PowerShell 7** (Windows users)

### 30-Second Setup

```bash
# Clone the repository
git clone https://github.com/SPRIME01/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run interactive setup
just setup
```

That's it! The setup wizard will guide you through the rest.

## Installation & Setup

### 1. Basic Setup (All Platforms)

The interactive setup wizard is the recommended way to install:

```bash
just setup
```

This command launches `scripts/setup-wizard-improved.sh` which provides:
- **Idempotent state management**: Tracks installed components to avoid redundant operations
- **Smart prompting**: Only asks about components not already installed
- **Failure recovery**: Identifies and allows retry of failed installations
- **Force reinstall option**: Option to reinstall all components
- **Comprehensive error handling**: Detailed status tracking and reporting

The improved wizard will:
- Detect your platform and shell
- Show current installation status (if any previous setup exists)
- Configure environment variables
- Set up Oh My Zsh (if desired)
- Install VS Code settings
- Configure MCP integration
- Set up SSH agent (where supported)
- Track all installation states for future runs

### 2. Windows-Specific Setup

For Windows users with PowerShell 7:

```bash
just setup-windows
```

This launches the PowerShell version of the setup wizard (`scripts/setup-wizard.ps1`) with Windows-specific optimizations.

### 3. Complete Windows Integration

For full Windows/WSL2 integration:

```bash
just setup-windows-integration
```

This comprehensive command:
- Sets up the projects directory with Windows access
- Configures PowerShell 7 profile
- Creates WSL-Windows symlinks
- Fixes shell configuration issues

### 4. Projects Directory Setup (Improved & Idempotent)

Create a unified projects directory with Windows access (WSL2):

```bash
just setup-projects
```

The **improved idempotent version** provides:

**Safe Operations**:
- ✅ Checks existing state before making changes
- ✅ Never overwrites working configurations
- ✅ Provides clear status of all operations
- ✅ Safe to run multiple times

**Smart Windows Integration**:
- Detects existing symlinks and preserves them
- Only creates batch file if symlink creation fails
- Handles permission requirements gracefully
- Provides manual instructions when needed

**What it creates**:
- `~/projects` directory in WSL2 (always safe)
- Windows symlink at `C:\Users\{username}\projects` (if possible)
- Batch file fallback: `projects.bat` (if symlink requires admin)
- PowerShell function integration (if available)

**Status Reporting**:
```bash
# Example output showing current state
✅ Projects directory ensured at ~/projects
✅ Windows symlink already exists and is working
🎉 Projects setup complete!
```

**Edge Cases Handled**:
- Existing directories (won't overwrite)
- Failed symlink creation (creates batch fallback)
- Missing permissions (provides manual instructions)
- Conflicting files (reports and suggests resolution)

## Command Reference

### Essential Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `just` | Show all available commands | Getting started |
| `just setup` | Interactive setup wizard | First-time installation |
| `just test` | Run all automated tests | Verify configuration |
| `just update` | Update dotfiles and reapply config | Keep system current |

### Setup & Installation

| Command | Platform | Description |
|---------|----------|-------------|
| `just setup` | Unix/Linux/macOS | **Improved** interactive setup wizard with state management |
| `just setup-original` | Unix/Linux/macOS | Original setup wizard (fallback) |
| `just setup-windows` | Windows | PowerShell setup wizard |
| `just setup-windows-integration` | WSL2 | Complete Windows integration |
| `just setup-projects` | WSL2 | **Idempotent** projects directory with Windows access |
| `just setup-pwsh7` | Windows | PowerShell 7 profile setup |

### Remote Development

| Command | Description | Requirements |
|---------|-------------|--------------|
| `just setup-wsl2-remote` | Configure WSL2 SSH server | WSL2 environment |
| `just setup-wsl2-remote-windows` | Windows firewall/networking | Administrator privileges |
| `just setup-wsl2-complete` | Guided remote dev setup | WSL2 + Windows |
| `just setup-remote-dev` | Alias for complete setup | WSL2 + Windows |

### SSH Agent Configuration

| Command | Description | Prerequisites |
|---------|-------------|---------------|
| `just setup-ssh-agent-windows` | Windows SSH agent auto-start | npiperelay via Scoop |
| `just enable-ssh-agent` | Enable SSH agent in zsh | npiperelay installed |

### Maintenance & Troubleshooting

| Command | Description | When to Use |
|---------|-------------|-------------|
| `just diagnose-shell` | Comprehensive shell diagnostics | Startup issues |
| `just fix-env-loading` | Fix environment loading issues | .env problems |
| `just fix-alias-conflicts` | Resolve alias/function conflicts | Parse errors |
| `just fix-pwsh7` | Repair PowerShell 7 profile | PowerShell issues |
| `just clean-old-powershell-profiles` | Remove conflicting profiles | Profile conflicts |

### Testing & Development

| Command | Description | Output |
|---------|-------------|--------|
| `just test` | Run all automated tests | Pass/fail results |

## Platform-Specific Guides

### Linux/macOS Setup

1. **Initial Setup**:
   ```bash
   just setup
   ```

2. **Choose Configuration Profile**:
   - `minimal`: Basic shell configuration
   - `developer`: Full development environment
   - `full`: Everything including MCP integration

3. **Post-Setup Verification**:
   ```bash
   just test
   just diagnose-shell
   ```

### Windows/WSL2 Setup

1. **Prerequisites**:
   - Install WSL2 with Ubuntu
   - Install PowerShell 7
   - Install Scoop (optional, for npiperelay)

2. **Complete Integration**:
   ```bash
   just setup-windows-integration
   ```

3. **Optional: SSH Agent Setup**:
   ```bash
   # Install npiperelay first
   scoop install npiperelay

   # Then enable SSH agent
   just enable-ssh-agent
   ```

4. **Remote Development** (optional):
   ```bash
   just setup-remote-dev
   ```

### Windows PowerShell Setup

For Windows-native PowerShell configuration:

1. **PowerShell 7 Profile**:
   ```bash
   just setup-pwsh7
   ```

2. **Fix Issues**:
   ```bash
   just fix-pwsh7
   just clean-old-powershell-profiles
   ```

## Advanced Configuration

### Environment Variables

The system supports multiple environment files:

- **Global**: `~/.env` (optional)
- **MCP**: `~/dotfiles/mcp/.env` (created during setup)
- **Custom**: Any `.env` file you specify

### Modular Architecture

The shell configuration uses a modular system:

```
shell/
├── common/              # Cross-shell configuration
├── platform-specific/  # OS-specific settings
├── bash/               # Bash-specific config
└── zsh/                # Zsh-specific config
```

### Security Features

- **File Permission Validation**: Ensures `.env` files have secure permissions (600)
- **Environment Variable Validation**: Checks for required variables
- **Input Sanitization**: Validates environment variable content
- **Pre-commit Hooks**: Prevents committing sensitive data

### Debug Mode

Enable detailed logging for troubleshooting:

```bash
export DOTFILES_DEBUG=true
```

### State Management & Idempotency

The improved setup wizard includes sophisticated state management to make all operations idempotent and reliable:

#### State File

The system maintains a state file at `~/dotfiles/.dotfiles-state` that tracks:
- **Installed components**: Successfully completed installations
- **Failed components**: Components that failed with error details
- **Skipped components**: Components explicitly skipped by user or system

#### Smart Setup Behavior

**First Run**:
- Prompts for all available components
- Creates state file to track selections and results

**Subsequent Runs**:
- Shows current installation status
- Only prompts for uninstalled or failed components
- Offers to retry failed components only
- Provides force reinstall option for all components

#### State Management Commands

```bash
# View current installation status
just setup  # Will show status if previous runs exist

# Force reinstall all components
just setup  # Choose "force reinstall" when prompted

# Retry only failed components
just setup  # Choose "retry failed only" when prompted
```

#### State File Format

```bash
# Example .dotfiles-state file
bash_config=installed
zsh_config=installed
pwsh_config=skipped # PowerShell not available
vscode_settings=failed # VS Code installer failed
git_hook=installed
projects_setup=installed
setup_completed=2025-08-05T10:30:00Z
```

#### Component States

- **`installed`**: Component successfully installed and configured
- **`failed`**: Installation failed with recorded error reason
- **`skipped`**: User chose not to install or system prerequisite missing

#### Benefits

✅ **Safe to re-run**: Never duplicates work or breaks existing config
✅ **Failure recovery**: Easily retry only what failed
✅ **Selective updates**: Install new components without affecting existing ones
✅ **Transparency**: Always shows what's installed and what's not
✅ **Time saving**: Skips already-completed work automatically

## Troubleshooting

### Common Issues & Solutions

#### 1. Powerlevel10k Instant Prompt Warnings

**Issue**: Console output interfering with instant prompt
**Solution**: Debug mode is now conditional - warnings should be resolved

#### 2. Oh My Zsh Not Loading

**Issue**: Shell starts but Oh My Zsh features missing
**Solution**:
```bash
just diagnose-shell
# If issues found:
just fix-env-loading
```

#### 3. SSH Agent Not Working

**Issue**: SSH keys not loading automatically
**Solution**:
```bash
# For Windows/WSL2:
scoop install npiperelay
just enable-ssh-agent
```

#### 4. PowerShell Profile Errors

**Issue**: PowerShell shows errors on startup
**Solution**:
```bash
just fix-pwsh7
just clean-old-powershell-profiles
```

#### 5. Environment Variables Not Loading

**Issue**: Custom environment variables not available
**Solution**:
```bash
just fix-env-loading
# Check your .env file permissions:
chmod 600 ~/dotfiles/mcp/.env
```

#### 6. State Management Issues

**Issue**: State file shows incorrect status
**Solution**:
```bash
# Reset specific component state
rm ~/dotfiles/.dotfiles-state  # Remove entire state file
just setup  # Re-run setup wizard

# Or manually edit state file
nano ~/dotfiles/.dotfiles-state
```

**Issue**: Want to reinstall specific component
**Solution**:
```bash
# Edit state file to remove component entry
sed -i '/^component_name=/d' ~/dotfiles/.dotfiles-state
just setup  # Will prompt for that component again
```

**Issue**: Setup wizard shows "already installed" but component not working
**Solution**:
```bash
# Force reinstall all components
just setup
# Choose "force reinstall all components" when prompted
```

### Diagnostic Commands

Run comprehensive diagnostics:

```bash
# Full system check
just diagnose-shell

# Specific issue checks
just fix-env-loading
just fix-alias-conflicts

# State management diagnostics
just setup  # Shows current installation status
cat ~/dotfiles/.dotfiles-state  # View raw state file
```

### State Management Diagnostics

**Check Installation Status**:
```bash
# Quick status check
just setup
# Will immediately show installation status if any setup has been done

# View state file directly
cat ~/dotfiles/.dotfiles-state
```

**Common State Patterns**:
```bash
# All components successful
bash_config=installed
zsh_config=installed
vscode_settings=installed

# Mixed success/failure (retry available)
zsh_config=installed
pwsh_config=failed # PowerShell bootstrap script failed
vscode_settings=skipped # user choice

# Fresh installation
# (file doesn't exist or is empty)
```

### Manual Recovery

If automatic fixes don't work:

1. **Backup Current Config**:
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.bashrc ~/.bashrc.backup
   ```

2. **Reset to Basic Configuration**:
   ```bash
   # Remove modular loading temporarily
   # Edit .zshrc to comment out dotfiles loading
   ```

3. **Gradual Re-enablement**:
   ```bash
   # Re-run setup with minimal profile
   just setup
   # Choose "minimal" when prompted
   ```

## Development & Testing

### Running Tests

Execute the full test suite:

```bash
just test
```

This runs:
- Shell configuration tests
- Environment loading tests
- PowerShell tests (if available)
- Integration tests

### Contributing

1. **Test Your Changes**:
   ```bash
   just test
   ```

2. **Verify Cross-Platform**:
   ```bash
   # Test on different shells
   bash -c "source ~/.bashrc"
   zsh -c "source ~/.zshrc"
   ```

3. **Check Security**:
   ```bash
   # Ensure no sensitive data in commits
   git log --oneline | head -10
   ```

### Custom Extensions

The modular system supports custom extensions:

1. **Add Custom Shell Functions**:
   ```bash
   # Create: shell/common/custom.sh
   # Add your functions there
   ```

2. **Platform-Specific Customizations**:
   ```bash
   # Create: shell/platform-specific/linux-custom.sh
   # Add platform-specific code
   ```

## Configuration Profiles

### Minimal Profile
- Basic shell configuration
- Essential aliases and functions
- No additional integrations

### Developer Profile
- Full development environment
- Git configurations
- Development tools and aliases
- VS Code integration

### Full Profile
- Everything in Developer
- MCP integration
- SSH agent setup
- Remote development support
- All optional features

## Update & Maintenance

### Regular Updates

Keep your dotfiles current:

```bash
just update
```

This command:
- Pulls latest changes from repository
- Reapplies configurations
- Updates any dependencies
- Validates configuration integrity

### Backup Strategy

Important files are automatically backed up during updates:
- Shell configuration files (`.zshrc`, `.bashrc`)
- PowerShell profiles
- Environment files

Backups are timestamped for easy recovery.

## Support & Resources

### Getting Help

1. **Check Installation Status**: `just setup` (shows current state)
2. **Run Diagnostics**: `just diagnose-shell`
3. **Check Documentation**: Review this guide
4. **Enable Debug Mode**: `export DOTFILES_DEBUG=true`
5. **Test Configuration**: `just test`
6. **View State File**: `cat ~/dotfiles/.dotfiles-state`

### Advanced Troubleshooting

**State File Issues**:
```bash
# Reset all state (forces fresh setup)
rm ~/dotfiles/.dotfiles-state
just setup

# Reset specific component
sed -i '/^component_name=/d' ~/dotfiles/.dotfiles-state
just setup
```

**Force Reinstallation**:
```bash
# Method 1: Use setup wizard option
just setup
# Choose "force reinstall all components"

# Method 2: Clear state and restart
rm ~/dotfiles/.dotfiles-state
just setup
```

### External Resources

- [Just Command Runner](https://github.com/casey/just)
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [WSL2 Documentation](https://docs.microsoft.com/en-us/windows/wsl/)

---

*This documentation is part of the modern dotfiles project. For the latest updates and information, visit the [project repository](https://github.com/SPRIME01/dotfiles).*
