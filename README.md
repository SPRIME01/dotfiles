# 🛠️ Dotfiles — Unified Shell Config & Dev Environment

Welcome to a portable developer cockpit. This setup brings together PowerShell 7, Zsh, and Bash into a unified, DRY, Git-synchronized environment that you can deploy anywhere, with:

- Cross-shell aliases and environment variables
- Machine-specific behavior
- Oh My Posh + PSReadLine UX polish
- **Lazy-loaded** PowerShell modules for faster startup
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
│   ├── Update-LazyLoaders.ps1       # Script to update lazy-loaders
│   └── Modules/
│       └── Aliases/
│           └── Aliases.psm1               # Custom PS aliases
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
  2. Run `PowerShell/Update-LazyLoaders.ps1` to update your profile

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
