# 🛠️ Dotfiles — Unified Shell Config & Dev Environment

Welcome to a portable developer cockpit. This setup brings together PowerShell 7, Zsh, and Bash into a unified, DRY, Git-synchronized environment that you can deploy anywhere, with:

- Cross-shell aliases and environment variables
- Machine-specific behavior
- Oh My Posh + PSReadLine UX polish
- **Lazy-loaded** PowerShell modules for faster startup
- **Auto-generated** PowerShell aliases with intelligent naming
- **Unified workflow** - one command to regenerate all aliases
- **20+ developer-focused PowerShell functions** for git, file management, system monitoring
- **Novice-friendly shortcuts** for common development tasks
- VS Code extension control
- Bootstrap scripts for full setup and provisioning

---

## 📁 File & Folder Overview

```text
dotfiles/
├── .shell_common                # Shared variables & aliases (bash + zsh)
├── .shell_theme_common          # Theme config (used in POSH only)
├── .bashrc                      # Bash startup → loads .shell_common
├── .zshrc                       # Zsh startup → loads .shell_common
├── bootstrap.sh                 # Shell bootstrap (symlinks & installs oh-my-posh)
├── bootstrap.ps1                # PowerShell bootstrap (symlinks, installs modules, etc.)
├── PowerShell/
│   ├── Microsoft.PowerShell_profile.ps1   # PowerShell profile
│   ├── powershell.config.json             # Enables unrestricted script execution
│   └── Modules/
│       └── Aliases/
│           ├── Aliases.psm1                    # Auto-generated custom PS aliases
│           ├── Update-AliasesModule.ps1        # Unified script to regenerate module
│           ├── Invoke-UpdateAliasesModule.ps1  # Wrapper function for updatealiases
│           ├── Get-AliasHelp.ps1               # Individual function files...
│           ├── Get-FileTree.ps1
│           ├── Set-ProjectRoot.ps1
│           └── *.ps1                           # Additional PowerShell functions
├── .vscode/                    # (optional) VS Code settings
│   └── settings.json
├── vscode-extensions.txt       # (optional) list of extensions to auto-install
└── README.md
```

---

## 🚀 How It Works

### 🔁 Shared Shell Logic (`.shell_common`)
- Defines `ProjectsHome` environment variable
- Adds helpful aliases like `projects`, `pcode`, and `dotfiles`
- Detects and configures based on your shell (zsh vs bash)
- Responds to the machine's hostname for workstation-specific overrides

Customize:
```bash
case "$(hostname)" in
  "workstation-name") export SPECIAL_VAR="true" ;;
  "dev-laptop") export SPECIAL_VAR="false" ;;
esac
```

### 🎨 Shared Shell UX (`.shell_theme_common`)
Used in PowerShell only — configures:

- Oh My Posh
- PSReadLine
- Terminal-Icons
- Optional prompt tweaks

---

### 🧠 Shell Startup Files

- `.bashrc` and `.zshrc` source `.shell_common` and `.shell_theme_common`
- PowerShell loads `Microsoft.PowerShell_profile.ps1`, which:
  - Sources `.shell_theme_common.ps1`
  - **Lazy-loads** modules in `PowerShell/Modules/` for faster startup
  - Applies machine-specific logic via `$env:COMPUTERNAME`

---

### ⚡ PowerShell Aliases System

The PowerShell aliases are **automatically managed** with a streamlined workflow:

#### **Built-in Aliases Available:**

**🗂️ Navigation & File Management:**
- `aliashelp` → Lists all aliases with descriptions
- `filetree` → Displays directory tree structure
- `finddir` → Find directories by partial name
- `explore` → Open current directory in Windows Explorer
- `sizes` → Show file sizes in human-readable format

**⚡ Git Workflow:**
- `gs` → Quick git status with branch info
- `gc` → Add all changes and commit with message

**🔧 Development Tools:**
- `projects` → Find and list all Node.js (package.json) and Python (pyproject.toml) projects
- `grep` → Search for text in files with colored output
- `json` → Pretty-print JSON files
- `killport` → Kill processes running on specific ports
- `testport` → Test if a port is open

**📊 System Monitoring:**
- `sysinfo` → Show CPU, memory, disk usage and uptime
- `netstat` → Display active network connections

**🛠️ Environment:**
- `projectroot` → Navigate to project directories
- `gensecret` → Generate secure keys
- `updateenv` → Update environment variables
- `updatealiases` → **Regenerate the entire aliases system**

#### **Adding New Functions:**
1. Create a new `.ps1` file in `PowerShell/Modules/Aliases/`
2. Write your function with proper comment-based help:
   ```powershell
   <#
   .SYNOPSIS
   Brief description of what the function does.
   #>
   function My-NewFunction {
       # Your code here
   }
   ```
3. Run `updatealiases` to automatically:
   - Regenerate `Aliases.psm1` with proper exports
   - Update the profile with lazy-loading functions
   - Create intelligent aliases (e.g., `Get-MyData` → `mydata`)

**That's it!** The system handles dot-sourcing, alias creation, and lazy-loading automatically.

---

### 🎯 Novice-Friendly Development Shortcuts

These aliases transform complex development tasks into simple commands:

#### **Quick Problem Solving:**
```powershell
killport 3000           # Development server won't start? Kill what's on the port
testport 8080           # Check if your app is running
sysinfo                 # Computer running slow? Check resources
gs                      # What's the git status? Quick check
```

#### **File & Project Management:**
```powershell
finddir "my-project"    # Can't remember where you put that project?
projects                # Show all Node.js and Python projects in this directory tree
grep "TODO"             # Find all your TODO comments
sizes                   # Which files are taking up space?
```

#### **One-Command Workflows:**
```powershell
gc "Fixed the bug"      # Add all changes and commit in one command
explore                 # Open current folder in Windows Explorer
json "package.json"     # Pretty-print any JSON file
```

#### **System Monitoring Made Easy:**
```powershell
netstat                 # See what's connected to your computer
sysinfo                 # CPU, memory, disk usage at a glance
```

**Perfect for beginners** - no need to remember complex command syntax or multiple steps!

---

### 📦 Bootstrap Scripts

#### 🟣 `bootstrap.ps1` (PowerShell)

- Creates symlinks to your PowerShell profile & `powershell.config.json`
- Installs: Oh My Posh, PSReadLine, Terminal-Icons
- Ensures PowerShell directory exists
- Logs what it links or installs

#### 🟢 `bootstrap.sh` (Bash/Zsh)

- Creates symlinks to `.bashrc`, `.zshrc`, `.shell_common`, and `.shell_theme_common`
- Installs Oh My Posh if missing

---

### 💻 VS Code Setup (Optional)

- Store your `settings.json` in `.vscode/`
- Save extensions:

  ```bash
  code --list-extensions > vscode-extensions.txt
  ```

- Restore on a new machine:

  ```bash
  cat vscode-extensions.txt | xargs -n 1 code --install-extension
  ```

---

## 🧪 Provisioning a New Machine

1. Clone this repo:

   ```bash
   git clone https://github.com/SPRIME01/dotfiles ~/dotfiles
   ```

2. Run one of:

   ```bash
   ./bootstrap.sh      # Bash/Zsh
   ./bootstrap.ps1     # PowerShell
   ```

Done. It will link your configs, install tools, and load your custom environment 🎯

---

## 🧹 Customizing

- **Add a new shell alias?**
  Add it to `.shell_common`

- **Tweak Oh My Posh or colors?**
  Edit `.shell_theme_common.ps1` and reload shell

- **Add a new PowerShell function?**
  1. Add a new `.ps1` file to `PowerShell/Modules/Aliases`
  2. Run `updatealiases` to automatically regenerate the module and profile

- **Need to see all available aliases?**
  Run `aliashelp` to display all aliases with descriptions

- **Want project-specific VS Code extensions?**
  Use `.vscode/extensions.json` in each repo and enable workspace recommendations

---

## 🔒 Security & Script Permissions

- `powershell.config.json` allows profiles & bootstraps to run even with restricted execution policies
- Scripts use `-Force`, fallback checks, and install verification to prevent errors

## 📦 One-Line Install

**PowerShell (Windows):**
```powershell
irm https://raw.githubusercontent.com/SPRIME01/dotfiles/main/install.ps1 | iex
```
**Bash/Zsh (Linux/Mac):**
```bash
curl -sSL https://raw.githubusercontent.com/SPRIME01/dotfiles/main/install.sh | bash
```

---

### 🔒 Safety Tip

Only include `bootstrap.ps1` / `bootstrap.sh` logic in those bootstraps — never run arbitrary scripts from unverified repos in the wild (but this one’s yours, so go wild 🚀)

---

## How to use remotely

**From any terminal:**
```bash
bash <(curl -s https://raw.githubusercontent.com/SPRIME01/dotfiles/main/update.sh)
```

**From PowerShell:**
```powershell
irm https://raw.githubusercontent.com/SPRIME01/dotfiles/main/update.ps1 | iex
```

---

## 🚀 Quick Reference

### PowerShell Aliases (Available after setup)
```powershell
# System & Navigation
aliashelp          # Show all available aliases
sysinfo            # System resources (CPU, memory, disk, uptime)
explore            # Open current directory in Explorer
finddir "pattern"  # Find directories by partial name
sizes              # Show file sizes in human-readable format

# Development Workflow
updatealiases      # Regenerate aliases module (after adding new functions)
projects           # Find and list all Node.js projects
grep "text"        # Search for text in files
json "file.json"   # Pretty-print JSON files

# Git Operations
gs                 # Quick git status
gc "message"       # Add all and commit

# Network & Processes
killport 3000      # Kill process on specific port
testport 8080      # Test if port is open
netstat            # Show active network connections

# Project Navigation
filetree           # Display directory tree
projectroot        # Navigate to projects
gensecret          # Generate secure keys
updateenv          # Update environment variables
```

### Adding New PowerShell Functions
```powershell
# 1. Create YourFunction.ps1 in PowerShell/Modules/Aliases/
# 2. Run this to regenerate everything:
updatealiases
```
