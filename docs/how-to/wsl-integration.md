# WSL Integration Configuration

This document describes the environment variables and functions available for WSL-Windows integration in the dotfiles setup.

## Environment Variables

These variables can be set in your `.env` file or in your shell environment to customize WSL-Windows integration:

### Projects Directory Configuration

- **`PROJECTS_ROOT`** (Bash/Zsh): Path to projects directory in WSL
  - Default: `$HOME/projects`
  - Example: `export PROJECTS_ROOT="$HOME/development"`

- **`WSL_PROJECTS_PATH`** (PowerShell): Windows path for projects symlink
  - Default: `$env:USERPROFILE\projects`
  - Example: `$env:WSL_PROJECTS_PATH = "C:\Development\Projects"`

### User Configuration

- **`WSL_USER`** (Both): WSL username for path construction
  - Default: `$USER` (Bash) / `$env:USERNAME` (PowerShell)
  - Example: `export WSL_USER="myusername"`

### Distribution Configuration

- **`WSL_DISTRO`** (Both): WSL distribution name
  - Default: Auto-detected from `$WSL_DISTRO_NAME` or `wsl.exe -l -v`
  - Example: `export WSL_DISTRO="Ubuntu-22.04"`

## Available Functions

### Bash/Zsh Functions

- **`projects`** - Navigate to projects directory
  - Usage: `projects`
  - Goes to: `$PROJECTS_ROOT`

### PowerShell Functions

- **`projects`** - Navigate to projects directory
  - Usage: `projects`
  - Goes to: `$env:PROJECTS_ROOT`

- **`Link-WSLProjects`** - Create Windows symlink to WSL projects directory
  - Usage: `Link-WSLProjects`
  - Creates symlink from `$WSL_PROJECTS_PATH` to WSL projects directory
  - Requires administrator privileges

## Automatic Setup

The dotfiles automatically configure WSL integration when sourced:

1. **SSH Keys**: Symlinks Windows SSH keys to WSL
2. **Kubernetes Config**: Symlinks Windows kubectl config to WSL
3. **Projects Directory**: Creates Windows batch file or symlink for easy access

## Manual Setup

### Using Just Commands

```bash
# Set up projects directory with Windows integration
just setup-projects
```

### Using Setup Wizard

```bash
# Run interactive setup
./scripts/setup-wizard.sh
```

### Manual PowerShell Symlink

Run PowerShell as Administrator:

```powershell
# Using the function
Link-WSLProjects

# Or manually
mklink /D "C:\Users\username\projects" "\\wsl.localhost\Ubuntu\home\username\projects"
```

## Configuration Examples

### Custom Projects Path

Add to your `.env` file:

```bash
# Bash/Zsh
PROJECTS_ROOT="$HOME/development/projects"

# For PowerShell integration
WSL_PROJECTS_PATH="C:\\Development\\Projects"
```

### Different WSL User

```bash
# If your WSL username differs from Windows username
WSL_USER="mylinuxuser"
```

### Specific Distribution

```bash
# If you have multiple WSL distributions
WSL_DISTRO="Ubuntu-22.04"
```

## Troubleshooting

### WSL Starting in Wrong Directory

If WSL starts in the Windows user directory (`/mnt/c/Users/username`) instead of your WSL home directory, this is usually a Windows Terminal configuration issue:

**Fix 1: Windows Terminal Settings**
1. Open Windows Terminal
2. Go to Settings (Ctrl+,)
3. Find your WSL profile (usually "Ubuntu" or similar)
4. Set the "Starting directory" to: `\\wsl.localhost\Ubuntu\home\%USERNAME%`
5. Or leave it empty to use the default WSL home directory

**Fix 2: WSL Configuration**
Run this command in PowerShell as Administrator:
```powershell
wsl --set-default-user <your-wsl-username>
```

**Automatic Fix**: The dotfiles include an automatic fix that detects when you start in the Windows directory and navigates to your WSL home directory.

### Symlink Creation Fails

- Ensure PowerShell is running as Administrator
- Check that WSL distribution is running
- Verify the target directory exists in WSL

### Projects Command Not Working

- Ensure `.shell_common.sh` is sourced in your shell profile
- Check that `PROJECTS_ROOT` is set correctly
- Verify the directory exists: `ls -la "$PROJECTS_ROOT"`

### WSL Path Resolution Issues

- Ensure WSL integration is enabled in Windows
- Check that `\\wsl.localhost\<distro>` path works in Windows Explorer
- Verify distribution name matches: `wsl.exe -l -v`

### Broken Windows Symlinks

If you see "Input/output error" when accessing the projects symlink:
```bash
# Remove broken symlink
rm /mnt/c/Users/$USER/projects
# Recreate it
just setup-projects
```
