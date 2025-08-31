# Cross-Platform Shell Configuration Setup Documentation

## Overview
This documentation describes a unified shell configuration system that works across Windows PowerShell, WSL2 Ubuntu (bash/zsh), providing consistent commands, aliases, and environment variables across all platforms.

## System Architecture

### Core Components
1. **Shared Configuration**: `.shell_common.sh` - Contains cross-platform environment variables and aliases
2. **Shell-Specific Configs**: Individual shell profiles that source the shared config
3. **Symlinks**: Connect Windows and WSL file systems for unified project access
4. **Environment Variables**: Consistent paths across all shells

### File Structure
```
~/dotfiles/
├── .shell_common.sh              # Shared cross-platform config
├── .zshrc                        # Zsh-specific configuration
├── .bashrc                       # Bash-specific configuration (stub)
└── PowerShell/
    ├── Microsoft.PowerShell_profile.ps1    # Main PowerShell profile
    ├── .shell_theme_common.ps1             # PowerShell theme/modules
    └── Themes/
        └── emodipt-extend.omp.json         # Oh My Posh theme
```

## Configuration Details

### 1. Shared Configuration (`.shell_common.sh`)
**Purpose**: Central location for cross-platform environment variables and aliases

**Key Features**:
- `PROJECTS_ROOT="$HOME/Projects"` - Unified project directory
- `DOTFILES_ROOT="$HOME/dotfiles"` - Dotfiles repository location
- `projects` alias - Quick navigation to projects directory
- Volta Node.js version manager integration
- Hostname-specific configurations
- Shell-specific welcome messages

**Location**: `~/dotfiles/.shell_common.sh`

### 2. WSL/Linux Shell Configurations

#### Zsh Configuration (`.zshrc`)
**Purpose**: Zsh-specific settings and shared config loading

**Key Features**:
- Sources `.shell_common.sh` for cross-platform consistency
- Zsh-specific configurations (compinit, history, globbing)
- Command auto-correction
- Extended globbing support

**Location**: `~/dotfiles/.zshrc` (symlinked to `~/.zshrc`)

#### Bash Configuration (`.bashrc`)
**Purpose**: Bash-specific settings with shared config integration

**Key Features**:
- Standard Ubuntu bash configuration
- Sources `.shell_common.sh` at the end
- Maintains existing bash-specific aliases and functions

**Location**: System `~/.bashrc` with shared config sourcing added

### 3. Windows PowerShell Configuration

#### Main Profile (`Microsoft.PowerShell_profile.ps1`)
**Purpose**: Primary PowerShell configuration with cross-platform consistency

**Key Features**:
- Oh My Posh initialization with custom theme
- Terminal-Icons and PSReadLine modules
- Lazy-loaded alias functions
- `projects` function using `$env:PROJECTS_ROOT`
- PNPM configuration

**Location**: `~/dotfiles/PowerShell/Microsoft.PowerShell_profile.ps1` (Windows `$PROFILE` is a symlink or loader that points to this file)

#### Theme Configuration (`.shell_theme_common.ps1`)
**Purpose**: PowerShell-specific theming and module management

**Key Features**:
- Lazy-loading Terminal-Icons
- PSReadLine configuration
- VS Code integration
- Custom Get-ChildItem function with icon support

**Location**: `~/dotfiles/PowerShell/.shell_theme_common.ps1`

## Cross-Platform Integration

### Environment Variables
- **WSL/Linux**: `PROJECTS_ROOT="$HOME/Projects"`
- **Windows**: `$env:PROJECTS_ROOT = "$HOME\Projects"`
- **Volta**: `VOLTA_HOME` and PATH integration across all shells

### Directory Symlinks
- **Windows**: `C:\Users\sprim\Projects` → WSL Projects directory
- **Purpose**: Both Windows and WSL access the same physical directory
- **Command**: `New-Item -ItemType SymbolicLink -Path "$HOME\Projects" -Target $wslProjectsPath`

### Profile Symlinks
- **PowerShell**: Windows `$PROFILE` points to the dotfiles repository (no OneDrive dependency)
- **WSL**: `~/.zshrc` → `~/dotfiles/.zshrc`
- **Purpose**: Single source of truth for all configurations

## Key Commands and Aliases

### Universal Commands (All Shells)
- `projects` - Navigate to projects directory
- `dotfiles` - Git operations on dotfiles repository
- `pcode` - Open projects directory in VS Code (if available)

### PowerShell-Specific Functions
- `finddir` - Directory search
- `grep` - Text search
- `gs` - Git status
- `explore` - Open Windows Explorer
- `killport` - Stop process by port
- `sysinfo` - System information

## Setup Process Summary

### Initial Setup Steps
1. **Created dotfiles repository** in `~/dotfiles`
2. **Fixed infinite recursion** in `.zshrc` (was sourcing itself)
3. **Resolved duplicate functions** in PowerShell profile
4. **Established symlinks** between Windows and WSL
5. **Centralized environment variables** in `.shell_common.sh`
6. **Fixed Oh My Posh conflicts** between main profile and theme file

### Critical Fixes Applied
1. **WSL Recursion**: Changed `.zshrc` from `source ~/dotfiles/.zshrc` to proper zsh configuration
2. **PowerShell Conflicts**: Removed duplicate `projects` functions, consolidated to single environment-variable-based function
3. **Oh My Posh**: Moved initialization to main profile, commented out in theme file
4. **Cross-Platform Paths**: Used environment variables instead of hardcoded paths
5. **Symlink Creation**: Established Windows ↔ WSL directory bridging

## Maintenance and Future Updates

### Adding New Cross-Platform Tools
1. **For Unix/Linux tools**: Add to `.shell_common.sh`
   ```bash
   # --- Tool Name ---
   if [ -d "$HOME/.tool" ]; then
       export TOOL_HOME="$HOME/.tool"
       export PATH="$TOOL_HOME/bin:$PATH"
   fi
   ```

2. **For PowerShell equivalent**: Add to PowerShell profile
   ```powershell
   # Tool Name configuration
   if (Test-Path "$HOME\.tool") {
       $env:TOOL_HOME = "$HOME\.tool"
       $env:Path = "$env:TOOL_HOME\bin;$env:Path"
   }
   ```

### Shell-Specific Configurations
- **Bash-only**: Keep in `.bashrc`
- **Zsh-only**: Keep in `.zshrc`
- **PowerShell-only**: Keep in PowerShell profile
- **Cross-platform**: Always add to `.shell_common.sh`

## Troubleshooting

### Common Issues and Solutions
1. **"Command not found: projects"**: Check if `.shell_common.sh` is being sourced
2. **Infinite recursion**: Ensure `.zshrc` doesn't source itself
3. **PowerShell theme not loading**: Verify oh-my-posh is only initialized once
4. **Path mismatches**: Ensure environment variables are set correctly in all shells
5. **Symlink issues**: Verify WSL is running and paths are accessible

### Verification Commands
```bash
# WSL/Linux
type projects
echo $PROJECTS_ROOT
projects && pwd

# PowerShell
projects ; pwd
echo "PROJECTS_ROOT = $env:PROJECTS_ROOT"
Get-Item $PROFILE | Select-Object FullName, LinkType, Target
```

## System Information
- **OS**: Windows 11 with WSL2 Ubuntu 24.04
- **Shells**: PowerShell 7.x, Zsh, Bash
- **Username Mapping**: Windows (`sprim`) ↔ WSL (`sprime01`)
- **Theme**: Oh My Posh with custom `emodipt-extend.omp.json`
- **Node Manager**: Volta
- **Package Manager**: PNPM

This setup provides a unified development environment where the `projects` command works consistently across all shells and platforms, taking you to the same physical directory regardless of whether you're in Windows PowerShell or WSL.
