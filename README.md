# 🛠️ Dotfiles — Unified Shell Config & Dev Environment

Welcome to a portable developer cockpit. This setup brings together PowerShell 7, Zsh, and Bash into a unified, DRY, Git-synchronized environment that you can deploy anywhere, with:

- **Cross-shell aliases and environment variables**
- **Machine-specific behavior**
- **Oh My Posh** (PowerShell) + **Oh My Zsh** (Linux/WSL2) for rich terminal experiences
- **PSReadLine** UX polish for PowerShell
- **Powerlevel10k** theme for Zsh with beautiful prompts
- **Lazy-loaded** PowerShell modules for faster startup
- **Auto-generated** PowerShell aliases with intelligent naming
- **Unified workflow** - one command to regenerate all aliases
- **20+ developer-focused PowerShell functions** for git, file management, system monitoring
- **Shared shell functions** for both bash and zsh
- **Novice-friendly shortcuts** for common development tasks
- VS Code extension control
- Bootstrap scripts for full setup and provisioning

---

## 📁 File & Folder Overview

```text
dotfiles/
├── .shell_common.sh             # Shared variables & aliases (bash + zsh)
├── .shell_functions.sh          # Shared shell functions (bash + zsh)
├── .shell_theme_common.ps1      # Theme config (used in PowerShell only)
├── .bashrc                      # Bash startup → loads .shell_common
├── .zshrc                       # Zsh startup → loads .shell_common + Oh My Zsh
├── .p10k.zsh                    # Powerlevel10k configuration template
├── bootstrap.sh                 # Shell bootstrap (symlinks & installs oh-my-posh/zsh)
├── bootstrap.ps1                # PowerShell bootstrap (symlinks, installs modules)
├── install_zsh.sh               # Oh My Zsh installation script for Linux/WSL2
├── PowerShell/
│   ├── Microsoft.PowerShell_profile.ps1   # PowerShell profile
│   ├── powershell.config.json             # Enables unrestricted script execution
│   ├── Themes/
│   │   ├── powerlevel10k_classic.omp.json  # Official Powerlevel10k classic theme
│   │   ├── powerlevel10k_modern.omp.json   # Official Powerlevel10k modern theme
│   │   ├── powerlevel10k_lean.omp.json     # Official Powerlevel10k lean theme
│   │   ├── minimal-clean.omp.json          # Clean minimalist theme
│   │   └── emodipt-extend.omp.json         # Original extended theme
│   └── Modules/
│       └── Aliases/
│           ├── Aliases.psm1                    # Auto-generated custom PS aliases
│           ├── Update-AliasesModule.ps1        # Unified script to regenerate module
│           ├── Invoke-UpdateAliasesModule.ps1  # Wrapper function for updatealiases
│           ├── Set-OhMyPoshTheme.ps1           # Theme management functions
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

### 🔁 Shared Shell Logic (`.shell_common.sh`)
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



### 🎨 Shared Shell UX (`.shell_theme_common.ps1`)
Used in PowerShell only — configures:

- Oh My Posh
- PSReadLine
- Terminal-Icons
- Optional prompt tweaks

#### **Oh My Posh Theme Management:**

The PowerShell setup now includes **official Powerlevel10k themes** that match your Zsh experience perfectly:

**Available Themes:**
- `powerlevel10k_classic` - Official Powerlevel10k classic theme (default)
- `powerlevel10k_modern` - Official Powerlevel10k modern theme
- `powerlevel10k_lean` - Official Powerlevel10k lean theme
- `minimal-clean` - Clean, minimalist theme with essential info
- `emodipt-extend` - Your original extended theme

**Theme Commands:**
```powershell
# Switch themes
settheme powerlevel10k_classic     # Official Powerlevel10k classic
settheme powerlevel10k_modern      # Official Powerlevel10k modern
settheme powerlevel10k_lean        # Official Powerlevel10k lean
settheme minimal-clean             # Switch to minimal theme

# Manage themes
gettheme                          # Show current theme
listthemes                        # List all available themes

# Environment variable override
$env:OMP_THEME = "powerlevel10k_modern.omp.json"   # Set theme for session
```

**Features of Official Powerlevel10k themes:**
- **Authentic Powerlevel10k look** - Direct ports from the original Zsh theme
- **Proper icon rendering** - Uses correct Nerd Font icons and Unicode symbols
- **Multi-line prompts** with clean separation (classic/modern)
- **Context-aware segments**: OS icon, directory, git status, user@host
- **Right-side information**: Execution time, status indicators
- **Dynamic colors**: Git status changes colors based on repo state
- **Multiple variants**: Choose between classic, modern, or lean layouts

The theme preference is automatically saved and persists across PowerShell sessions.

---

### 🧠 Shell Startup Files


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

## 🐚 Zsh Setup (Linux/WSL2)

For Linux/WSL2 environments, this dotfiles setup includes a complete Oh My Zsh configuration with modern terminal enhancements:

### **What's Included:**
- **Oh My Zsh**: Feature-rich Zsh framework with extensive plugin ecosystem
- **Powerlevel10k**: Fast, beautiful, and customizable prompt theme (similar to Oh My Posh)
- **Smart Plugins**:
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-syntax-highlighting` - Command syntax highlighting
  - `history-substring-search` - Enhanced history search
  - `git`, `docker`, `kubectl`, `node`, `python` - Context-aware completions
- **MesloLGS NF Fonts**: Automatically downloaded and installed for optimal display
- **Shared Functions**: All the convenience functions from `.shell_functions.sh`

### **Installation:**
The Zsh setup is automatically included when running `./bootstrap.sh` on Linux/WSL2:

```bash
# Full setup (includes Zsh)
git clone https://github.com/SPRIME01/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

### **Manual Zsh Installation:**
```bash
# Install just the Zsh components
./install_zsh.sh

# Configure the beautiful Powerlevel10k theme
p10k configure
```

### **Zsh-Specific Features:**

#### **Enhanced Aliases:**
```bash
# Quick directory listings
ll                      # Detailed list with hidden files
la                      # All files including hidden
l                       # Simple list

# Git shortcuts (in addition to shared ones)
gst                     # git status
gco                     # git checkout
gcb <branch>            # git checkout -b (create new branch)
gaa                     # git add --all
gcm "message"           # git commit -m
gp                      # git push
gl                      # git pull
glog                    # git log --oneline --graph --decorate
```

#### **Powerful Functions:**
```bash
# Project & Directory Management
take myproject          # Create directory and cd into it
proj                    # Go to projects root, or proj <name> for specific project
backup myfile.txt       # Create timestamped backup

# Development Helpers
qcommit "fix bug"       # Quick add all + commit
killport 3000           # Kill process on port 3000
extract archive.zip     # Universal archive extractor

# System Utilities
myip                    # Get your public IP
weather                 # Current weather (or weather <city>)
dirsize                 # Size of current directory
findlarge 100M          # Find files larger than 100MB
sysinfo                 # Comprehensive system information

# Docker shortcuts
dps                     # Pretty docker ps
dlogs <container>       # Follow logs for container
dexec <container>       # Execute bash in container

# Git utilities
gclean                  # Clean up merged branches and optimize repo
gundo                   # Undo last commit (soft reset)

# Node.js/NPM helpers
npmglobal               # List global npm packages
nodecheck               # Show Node, NPM, Yarn, PNPM versions

# MCP integration
mcpstatus               # Show MCP servers configuration
mcpenv                  # Show MCP environment variables

# Quick notes
note "Remember to..."   # Add timestamped note to daily file
note                    # Open today's note file in editor
```

#### **Smart History & Navigation:**
- **Substring Search**: Use ↑/↓ arrows to search through command history
- **Auto-suggestions**: Type the beginning of a command to see suggestions
- **Smart Completions**: Tab completion for git branches, docker containers, etc.
- **Syntax Highlighting**: Commands turn green when valid, red when invalid

### **Customization:**

#### **Theme Configuration:**
The Powerlevel10k theme can be reconfigured anytime:
```bash
p10k configure          # Interactive theme configuration wizard
```

#### **Adding Plugins:**
Edit `.zshrc` and add plugins to the `plugins` array:
```bash
plugins=(
    git
    zsh-autosuggestions
    # Add your plugins here
    new-plugin-name
)
```

#### **Custom Functions:**
Add your own functions to `.shell_functions.sh` - they'll be available in both bash and zsh.

### **Tips & Tricks:**
- **Font Setup**: Set your terminal font to "MesloLGS NF" for best visual experience
- **Key Bindings**:
  - `Ctrl+Space`: Menu complete
  - `Ctrl+R`: Search command history
  - `Ctrl+A`: Beginning of line
  - `Ctrl+E`: End of line
- **Quick Navigation**: Use `take` instead of `mkdir && cd`
- **Git Workflow**: Use `gst` → `gaa` → `gcm "message"` → `gp` for common git operations

---

### 📦 Bootstrap Scripts

#### 🟣 `bootstrap.ps1` (PowerShell)

- Creates symlinks to your PowerShell profile & `powershell.config.json`
- Installs: Oh My Posh, PSReadLine, Terminal-Icons
- **Installs Oh My Posh** for shell customization
- Ensures PowerShell directory exists
- Logs what it links or installs

#### 🟢 `bootstrap.sh` (Bash/Zsh)

- Creates symlinks to `.bashrc`, `.zshrc`, `.shell_common`, and `.shell_theme_common`
- **Installs Oh My Posh** for shell customization
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

## 🩺 Health Check (doctor)

Run a quick status report of your setup without making changes:

```bash
bash scripts/doctor.sh
```

It checks:
- zsh, Oh My Zsh, and oh-my-posh availability
- PATH includes common user bins (~/.local/bin, ~/.cargo/bin, Pulumi, Volta)
- Valid JSON for `mcp/servers.json` (if `jq` is installed)
- On WSL, prerequisites for the SSH agent bridge (socat/npiperelay)
- Best‑effort VS Code terminal defaults and zsh path

Note: All warnings are informational; no side effects.

Flags:
- --quick (-q): Skip slower optional checks (fonts, WSL bridge, VS Code parsing)
- --verbose (-v): Print additional information while checking

---

## 🧪 Provisioning a New Machine

1. Clone this repo:

```bash
git clone https://github.com/SPRIME01/dotfiles ~/dotfiles
```

2. Run one of:

```bash
./bootstrap.sh      # Bash/Zsh (installs oh-my-posh)
./bootstrap.ps1     # PowerShell (installs oh-my-posh + modules)
```

3. **Restart your shell** to activate Python environment management

Done. It will link your configs, install tools (including Python version management), and load your custom environment 🎯

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
projects           # Find and list all Node.js and Python projects
grep "text"        # Search for text in files
json "file.json"   # Pretty-print JSON files

# Python Environment


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
