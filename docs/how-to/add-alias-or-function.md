# How-To: Add an Alias or Function Across All Shells

> **Type:** Diátaxis How-To Guide (Goal-oriented, practical task)  
> **Goal:** Introduce a new custom command that works identically in Bash, Zsh, and Windows PowerShell 7  
> **Prerequisites:** Access to the `dotfiles/` repository  

---

## 1. Decision Matrix: Where Does Your Code Belong?

| Command Type | Target Files |
| :--- | :--- |
| **Simple Navigation / Short Command Alias** | `shell/common/aliases.sh` (POSIX) **and** `shell/common/aliases.ps1` (PowerShell) |
| **Standalone Shell Function (<10 lines)** | `shell/common/functions.sh` (POSIX) **and** `shell/common/functions.ps1` (PowerShell) |
| **Complex PowerShell Cmdlet (multi-step, params)** | `PowerShell/Modules/Aliases/<Verb-Noun>.ps1` (exported in `Aliases.psm1`) |
| **Windows-Only Command** | `shell/platform-specific/windows.ps1` |
| **Linux/WSL-Only Command** | `shell/platform-specific/linux.sh` |
| **Personal Private Alias (Unversioned)** | `~/.zshrc.local` |

---

## 2. Procedure: Adding a Simple Cross-Platform Alias

Let's add a new alias `gco` for `git checkout`.

### Step 1: Add to POSIX Shells
Open `shell/common/aliases.sh` and add:
```bash
alias gco='git checkout'
```

### Step 2: Add to PowerShell
Open `shell/common/aliases.ps1` and add:
```powershell
Set-Alias -Name gco -Value "git checkout" -Force
```

### Step 3: Test and Reload
- In Bash/Zsh: Run `source ~/.zshrc` (or `source ~/.bashrc`) and test: `gco --help`.
- In PowerShell: Re-open the terminal or run `. $PROFILE` and test: `gco --help`.

---

## 3. Procedure: Adding a Complex PowerShell Cmdlet with Lazy-Loading

If you add a complex function to the PowerShell `Aliases` module:

### Step 1: Create the Cmdlet
Create a new file `PowerShell/Modules/Aliases/Get-DiskHealth.ps1`:
```powershell
function Get-DiskHealth {
    [CmdletBinding()]
    param()
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
}
```

### Step 2: Export in `Aliases.psm1`
Open `PowerShell/Modules/Aliases/Aliases.psm1` and add:
```powershell
. "$PSScriptRoot/Get-DiskHealth.ps1"
Export-ModuleMember -Function Get-DiskHealth
```

### Step 3: Regenerate Proxy Stubs
Execute the proxy generator:
```powershell
# Inside a PowerShell 7 session:
updatealiases
```
Or from WSL:
```bash
pwsh.exe -NoProfile -File PowerShell/Modules/Aliases/Update-AliasesModule.ps1
```

*Verification:* Inspect the bottom of `PowerShell/Microsoft.PowerShell_profile.ps1`. You will see the auto-generated proxy:
```powershell
function Get-DiskHealth { Import-Module $aliasesModulePath -Force; Get-DiskHealth @args }
```

---

## 4. Source Trail
- `shell/common/aliases.sh`
- `shell/common/aliases.ps1`
- `PowerShell/Modules/Aliases/Aliases.psm1`
- `PowerShell/Modules/Aliases/Update-AliasesModule.ps1`
- `PowerShell/Microsoft.PowerShell_profile.ps1`
